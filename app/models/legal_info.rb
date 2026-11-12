# Singleton: the seller's legal identity (shown in the footer and on every
# policy page, as the card schemes require) and the text of the five policy
# pages — Terms & Conditions, Refund, Return, Cancellation and Delivery.
#
# Policy texts are plain text, edited in admin:
#   - blocks are separated by a blank line;
#   - a block starting with "## " is a heading;
#   - a block whose lines all start with "- " is a bulleted list;
#   - {{company}}, {{company_id}}, {{vat}}, {{address}}, {{email}}, {{phone}}
#     and {{seller}} (name, ID and address in one line) are filled in from the
#     company details, so the texts stay right when those change.
class LegalInfo < ApplicationRecord
  PAGES = {
    "terms"        => { column: :terms,               title: "Terms & Conditions",  path: "terms" },
    "refunds"      => { column: :refund_policy,       title: "Refund Policy",       path: "refund-policy" },
    "returns"      => { column: :return_policy,       title: "Return Policy",       path: "return-policy" },
    "cancellation" => { column: :cancellation_policy, title: "Cancellation Policy", path: "cancellation-policy" },
    "delivery"     => { column: :delivery_terms,      title: "Delivery Terms",      path: "delivery-terms" }
  }.freeze

  def self.instance
    first || create!(email: "b_taynova@bondart.eu", phone: "+359 88 544 8888",
                     **DEFAULTS.transform_keys { |k| PAGES[k][:column] })
  end

  def self.page(key) = PAGES.fetch(key)

  def company? = company_name.present?

  # "Preciso Ltd, UIC 123456789, Sofia, …" — whatever is filled in.
  def seller_line
    [ company_name, (company_id.present? ? "UIC #{company_id}" : nil), address ].compact_blank.join(", ")
  end

  def text_for(key)
    raw = self[PAGES.fetch(key)[:column]].presence || DEFAULTS.fetch(key)
    fill(raw)
  end

  # The parsed text: [[:h, "Heading"], [:p, "Paragraph"], [:ul, ["a", "b"]], …]
  def blocks_for(key)
    text_for(key).split(/\r?\n\s*\r?\n/).map(&:strip).reject(&:empty?).map do |block|
      lines = block.lines.map(&:strip)
      if block.start_with?("## ")
        [ :h, block.delete_prefix("## ").strip ]
      elsif lines.all? { |l| l.start_with?("- ") }
        [ :ul, lines.map { |l| l.delete_prefix("- ").strip } ]
      else
        [ :p, lines.join(" ") ]
      end
    end
  end

  private

  def fill(text)
    values = {
      "company" => company_name, "company_id" => company_id, "vat" => vat_number,
      "address" => address, "email" => email, "phone" => phone, "seller" => seller_line
    }
    text.gsub(/\{\{\s*(\w+)\s*\}\}/) { values.fetch($1, "").presence || "—" }
  end

  DEFAULTS = {
    "terms" => <<~TEXT,
      ## Who we are

      The online shop at www.precisodesign.com ("the shop") is run by {{seller}} ("we", "us"). Contact: {{email}}, {{phone}}.

      These terms apply to every order placed through the shop. By placing an order you confirm that you have read and accept them, together with our Delivery Terms, Cancellation Policy, Return Policy and Refund Policy, which form part of these terms.

      ## The pieces

      Every piece is made by hand in porcelain. Small differences in shape, size, colour and glaze from the photographs are part of how each piece is made and are not a defect. Photographs and measurements are given as accurately as we can.

      ## Orders and the contract

      You place an order by completing the checkout. We then send you an email confirming that we have received it. The contract between you and us is concluded when we confirm your order — for card payments, when the payment is approved; for orders without online payment, when we confirm the pieces, the total and how to pay by email.

      If a piece turns out to be unavailable, or a price was shown in error, we will tell you and you may choose to continue or cancel; anything you have paid is refunded in full.

      ## Prices and payment

      Prices are in euro (€) and are the final price of the piece. The cost of delivery is shown separately at checkout before you pay, or, for countries without a set delivery price, is quoted to you by email before you pay.

      Card payments are processed securely by myPOS. We never see or store your card details. For orders without online payment, we email you how to pay.

      ## Delivery

      Delivery options, costs and times are described in our Delivery Terms.

      ## Cancellation, returns and refunds

      You may cancel an order that has not yet been dispatched, and as a consumer you have the right to withdraw from the purchase within 14 days of receiving it, without giving a reason. Details are in our Cancellation Policy, Return Policy and Refund Policy.

      ## Faulty or damaged pieces

      You have the legal guarantee of conformity under Bulgarian law: we are responsible for any lack of conformity that appears within two years of delivery. If a piece arrives damaged or faulty, please contact us as described in our Return Policy and we will repair, replace or refund it.

      ## Personal data

      We use the details you give at checkout (name, email, phone and delivery address) only to process, deliver and support your order, and keep them as long as the law requires for our records. They are shared only with the courier delivering your order and with myPOS for card payments. You may ask us at any time to see, correct or delete your data by writing to {{email}}.

      ## Complaints and disputes

      If you have a complaint, please write to us at {{email}} first — we will reply as soon as we can and within 14 days. If we cannot resolve it, you may contact the Bulgarian Commission for Consumer Protection (www.kzp.bg).

      These terms are governed by Bulgarian law. Nothing in them limits the rights you have as a consumer under the law of the country where you live.
    TEXT

    "refunds" => <<~TEXT,
      ## When you get a refund

      We refund your payment in full when:

      - you cancel an order before it is dispatched (see our Cancellation Policy);
      - you withdraw from the purchase within 14 days of receiving it and return the pieces (see our Return Policy);
      - a piece arrives damaged or faulty and cannot be replaced;
      - we cannot fulfil your order, for example because a piece is no longer available.

      ## What is refunded

      We refund the price of the pieces and the original delivery cost you paid. If you withdraw from only part of an order, the delivery cost is not refunded. If you chose a delivery method more expensive than our standard one, we refund only the cost of the standard delivery. The cost of sending pieces back to us is yours, unless the piece was damaged, faulty or not what you ordered.

      ## How and when

      Refunds are made within 14 days of the day we receive your cancellation or withdrawal. For a return, we may wait until we have received the pieces back, or until you show us proof that you have sent them, whichever is earlier.

      We refund using the same payment method you used — card payments are returned to the same card through myPOS — unless you expressly agree to a different method. You will not pay any fee for the refund. The time it takes the money to appear on your statement depends on your bank.

      ## Questions

      Write to {{email}} or call {{phone}}.
    TEXT

    "returns" => <<~TEXT,
      ## Your right to withdraw

      As a consumer you may withdraw from your purchase within 14 days of the day you (or someone you name, other than the courier) receive the pieces, without giving any reason.

      To withdraw, tell us clearly before the 14 days end — by email to {{email}} or by phone on {{phone}}, with your order number. A short message such as "I wish to return order PR-1050" is enough. You may also use the standard withdrawal form from Annex 6 to the Bulgarian Consumer Protection Act, but you do not have to.

      ## Sending pieces back

      Please send the pieces back to {{address}} without undue delay and no later than 14 days after telling us you are withdrawing. Porcelain is fragile: pack each piece carefully, ideally in its original packaging, so it arrives unbroken.

      The cost of sending the pieces back is yours. You are responsible for any loss in value caused by handling the pieces more than needed to examine them, and for damage caused by poor packing.

      ## Exceptions

      The right of withdrawal does not apply to pieces made to your own specification or clearly personalised for you, such as a commissioned piece or one made in a size, glaze or inscription you asked for.

      ## Damaged, faulty or wrong pieces

      If a piece arrives broken, faulty or is not what you ordered, please let us know within 3 days of delivery, with a photograph of the piece and the packaging, at {{email}}. We will replace it, or refund it in full, including delivery. In such cases you do not pay any cost of returning it. This does not affect your legal guarantee of conformity, which lasts two years from delivery.

      Refunds for returned pieces are made as described in our Refund Policy.
    TEXT

    "cancellation" => <<~TEXT,
      ## Cancelling your order

      You may cancel your order free of charge at any time before it is dispatched. Write to {{email}} or call {{phone}} with your order number. We will confirm the cancellation by email.

      Anything you have already paid is refunded in full — including delivery — within 14 days, to the same card or payment method you used. See our Refund Policy.

      ## After dispatch

      Once your order has been dispatched it can no longer be cancelled, but you can still withdraw from the purchase within 14 days of receiving it and return the pieces. See our Return Policy.

      ## Made-to-order pieces

      A piece made to your own specification can be cancelled free of charge until we have started making it. After that, we will tell you whether a cancellation is still possible.

      ## Cancellation by us

      We may cancel an order if a piece is no longer available, if payment is not completed, or if a price or description was shown in clear error. We will tell you by email and refund in full anything you have paid.
    TEXT

    "delivery" => <<~TEXT
      ## Where we deliver

      We deliver to the countries listed at checkout. For each country you can choose how your order is delivered — to an address, or to a courier office for collection — and the delivery price is shown before you pay.

      If your country is not listed, you can still place an order: we will email you the delivery cost and how to pay before anything is charged.

      ## How long it takes

      Pieces in stock are usually packed and dispatched within 3 working days of payment (or of our confirmation, for orders paid later). Courier delivery then usually takes 1–3 working days within Bulgaria and 3–10 working days to other countries. If a piece is made to order, or the studio is closed for a holiday, we will tell you the expected time before you pay.

      We will email you when your order is on its way.

      ## Delivery cost

      The delivery cost depends on the country and the delivery option you choose, and is shown at checkout and in your order confirmation. Orders outside the European Union may be subject to import duties and taxes charged by the destination country; these are paid by the recipient.

      ## Packing and receiving

      Every piece is packed by hand to travel safely. When you receive your parcel, please check it in front of the courier if you can. If a piece arrives damaged, let us know within 3 days at {{email}}, with photographs, and we will replace or refund it — see our Return Policy.

      The risk of loss or damage passes to you when you, or someone you name other than the courier, receive the parcel.

      ## Questions

      Write to {{email}} or call {{phone}}.
    TEXT
  }.freeze
end
