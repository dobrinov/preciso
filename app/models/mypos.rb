require "openssl"
require "base64"
require "json"

# myPOS Checkout (IPC API v1.4) — hosted payment page.
#
# Flow: we build a signed IPCPurchase form and the customer's browser posts it
# to myPOS. After payment myPOS calls URL_Notify server-to-server
# (IPCPurchaseNotify) — that call, verified with myPOS's public certificate, is
# the ONLY thing that marks an order paid. URL_OK / URL_Cancel are just browser
# redirects back to the shop.
#
# Signing (per the official myPOS SDK): take the parameter VALUES in the exact
# order they are posted, join them with "-", Base64-encode that string, sign it
# with RSA-SHA256 using our private key, Base64-encode the signature, and send
# it as the last parameter "Signature". Incoming calls are verified the same
# way, against every received field except Signature, in received order.
#
# Configuration (ENV, e.g. `fly secrets set`):
#   MYPOS_CONFIG_PACKAGE  the "configuration package" generated in the myPOS
#                         account (Base64 JSON: sid, cn, pk, pc, idx) — easiest
#   — or individually —
#   MYPOS_SID, MYPOS_WALLET_NUMBER, MYPOS_KEY_INDEX,
#   MYPOS_PRIVATE_KEY (PEM), MYPOS_PUBLIC_CERT (PEM, myPOS's certificate)
#
#   MYPOS_SANDBOX=1       post to the test endpoint (no real money)
#   MYPOS_CURRENCY        default EUR (must be enabled on the myPOS account)
#   MYPOS_LANGUAGE        payment page language, default EN
#
# When nothing is configured, online payment is off and checkout behaves as
# before (order placed, studio arranges payment by hand).
module Mypos
  PRODUCTION_URL = "https://www.mypos.com/vmp/checkout".freeze
  SANDBOX_URL    = "https://www.mypos.com/vmp/checkout-test".freeze
  VERSION        = "1.4".freeze

  class Error < StandardError; end

  Config = Struct.new(:sid, :wallet, :key_index, :private_key, :public_key, keyword_init: true)

  module_function

  def enabled? = config.present?

  def sandbox? = ActiveModel::Type::Boolean.new.cast(ENV["MYPOS_SANDBOX"]) || false

  def endpoint = sandbox? ? SANDBOX_URL : PRODUCTION_URL

  def currency = ENV.fetch("MYPOS_CURRENCY", "EUR").upcase

  def language = ENV.fetch("MYPOS_LANGUAGE", "EN").upcase

  def config
    return @config if defined?(@config)
    @config = load_config
  end

  # Ordered params (incl. Signature) for the IPCPurchase form.
  def purchase_params(order, ok_url:, cancel_url:, notify_url:)
    first, *rest = order.customer_name.to_s.strip.split(/\s+/)
    family = rest.join(" ").presence || first

    params = {
      "IPCmethod" => "IPCPurchase",
      "IPCVersion" => VERSION,
      "IPCLanguage" => language,
      "SID" => config.sid,
      "WalletNumber" => config.wallet,
      "KeyIndex" => config.key_index,
      "Currency" => currency,
      "Amount" => amount(order.total),
      "OrderID" => order.number,
      "URL_OK" => ok_url,
      "URL_Cancel" => cancel_url,
      "URL_Notify" => notify_url,
      "CustomerEmail" => order.customer_email.to_s,
      "CustomerPhone" => order.customer_phone.to_s,
      "CustomerFirstNames" => first.to_s,
      "CustomerFamilyName" => family.to_s,
      "CartItems" => order.order_lines.size.to_s
    }
    order.order_lines.each.with_index(1) do |line, i|
      params["Article_#{i}"]  = line.display_name.to_s
      params["Quantity_#{i}"] = line.qty.to_s
      params["Price_#{i}"]    = amount(line.price)
      params["Amount_#{i}"]   = amount(line.subtotal)
      params["Currency_#{i}"] = currency
    end
    params["CardTokenRequest"] = "0"          # don't store cards
    params["PaymentParametersRequired"] = "1" # we send full customer details

    params.merge("Signature" => sign(params.values))
  end

  # Verifies an incoming myPOS POST. `pairs` is the raw body decoded as ordered
  # [name, value] pairs (order matters for the signature).
  def valid_signature?(pairs)
    signature = pairs.find { |k, _| k.casecmp?("signature") }&.last
    return false if signature.blank?
    values = pairs.reject { |k, _| k.casecmp?("signature") }.map(&:last)
    data = Base64.strict_encode64(values.join("-"))
    config.public_key.verify(OpenSSL::Digest.new("SHA256"), Base64.decode64(signature), data)
  rescue OpenSSL::PKey::PKeyError, ArgumentError
    false
  end

  # Prices in this shop are whole euros; myPOS wants "12.00".
  def amount(n) = format("%.2f", n.to_d)

  def sign(values)
    data = Base64.strict_encode64(values.join("-"))
    Base64.strict_encode64(config.private_key.sign(OpenSSL::Digest.new("SHA256"), data))
  end

  def load_config
    raw =
      if ENV["MYPOS_CONFIG_PACKAGE"].present?
        pkg = JSON.parse(Base64.decode64(ENV["MYPOS_CONFIG_PACKAGE"].strip))
        { sid: pkg["sid"], wallet: pkg["cn"], key_index: pkg["idx"], private_key: pkg["pk"], public_cert: pkg["pc"] }
      else
        { sid: ENV["MYPOS_SID"], wallet: ENV["MYPOS_WALLET_NUMBER"], key_index: ENV["MYPOS_KEY_INDEX"],
          private_key: ENV["MYPOS_PRIVATE_KEY"], public_cert: ENV["MYPOS_PUBLIC_CERT"] }
      end
    return nil if raw.values.any?(&:blank?)

    Config.new(
      sid: raw[:sid].to_s, wallet: raw[:wallet].to_s, key_index: raw[:key_index].to_s,
      private_key: OpenSSL::PKey::RSA.new(pem(raw[:private_key])),
      public_key: public_key_from(pem(raw[:public_cert]))
    )
  rescue JSON::ParserError, OpenSSL::OpenSSLError => e
    raise Error, "myPOS configuration is invalid: #{e.message}"
  end

  # Secrets set via a shell often arrive with literal "\n" instead of newlines.
  def pem(str) = str.to_s.gsub("\\n", "\n").strip

  def public_key_from(pem)
    pem.include?("CERTIFICATE") ? OpenSSL::X509::Certificate.new(pem).public_key : OpenSSL::PKey.read(pem)
  end
end
