# ============================================================
# Preciso — seed catalogue (ported from the design prototype)
# Idempotent: safe to run repeatedly.
# ============================================================

CATEGORIES = [
  { slug: "bowls",    name: "Bowls",         blurb: "Hand-built forms for everyday and table." },
  { slug: "cups",     name: "Cups",          blurb: "For coffee, tea, and slow mornings." },
  { slug: "espresso", name: "Espresso Cups", blurb: "Small, dense, made for a single shot." },
  { slug: "vases",    name: "Vases",         blurb: "Stems, buds, and quiet sculpture." },
  { slug: "plates",   name: "Plates",        blurb: "Coupe and rimmed, glazed to the edge." }
]

CATEGORIES.each_with_index do |c, i|
  Category.find_or_create_by!(slug: c[:slug]) do |cat|
    cat.name = c[:name]
    cat.blurb = c[:blurb]
    cat.position = i
    cat.tone = Category::TONES[c[:slug]]
  end
end

cat = Category.all.index_by(&:slug)

PRODUCTS = [
  { id: "p-hakume", name: "Hakume Serving Bowl", category: "bowls", price: 58,
    short: "Wide bowl brushed with white slip.",
    long: "A generous serving bowl shaped in fine porcelain and finished with hakume — a brushed coat of white slip that leaves soft, gestural strokes under a clear glaze. Each one carries the mark of the brush, so no two are alike. Roughly 24 cm across." },
  { id: "p-everyday", name: "Everyday Bowl", category: "bowls", price: 32,
    short: "The one you reach for every day.",
    long: "An honest, medium bowl sized for cereal, soup, or a single serving of pasta. Unglazed foot, satin-white interior. Stacks neatly. About 15 cm across." },
  { id: "p-fold", name: "Fold Bowl", category: "bowls", price: 26,
    short: "Small bowl with a pinched fold.",
    long: "A little bowl with one pinched fold in the rim — a quiet gesture left from the hand. For dips, salt, olives, or rings at the end of the day. About 11 cm." },
  { id: "p-morning", name: "Morning Cup", category: "cups", price: 38,
    short: "Handle-less cup for the first coffee.",
    long: "A handle-less cup that sits warm in two hands. Thin at the lip, heavier at the base so it settles on the table. Holds about 220 ml." },
  { id: "p-tumbler", name: "Ribbed Tumbler", category: "cups", price: 34,
    short: "Faceted tumbler, fine vertical ribs.",
    long: "Shaped and then ribbed by hand while the clay is soft, giving a column of fine facets that catch the light. For water, wine, or a flat white. About 250 ml." },
  { id: "p-espresso", name: "Espresso Cup", category: "espresso", price: 24,
    short: "Small and dense, for a single shot.",
    long: "A compact espresso cup with a thick wall that holds heat. Bright white inside to read the crema, raw porcelain on the foot. About 70 ml." },
  { id: "p-espresso-ribbed", name: "Ribbed Espresso", category: "espresso", price: 26,
    short: "Espresso cup with a faceted body.",
    long: "The espresso cup with the tumbler's hand-ribbed facets. Sold singly so you can build the set you want. About 70 ml." },
  { id: "p-stem", name: "Stem Vase", category: "vases", price: 72,
    short: "Tall, narrow neck for a single stem.",
    long: "A slim vase with a narrow neck that holds a single stem upright — a branch, a ranunculus, one tulip going its own way. Glazed inside to hold water. About 28 cm tall." },
  { id: "p-bud", name: "Bud Vase", category: "vases", price: 44,
    short: "Round little vase for cuttings.",
    long: "A rounded bud vase for short cuttings and herbs from the windowsill. Sits well in a group of three. About 12 cm." },
  { id: "p-column", name: "Column Vase", category: "vases", price: 96,
    short: "Sculptural column, matte white.",
    long: "A larger column vase finished in a dry matte white glaze that reads almost like plaster. Works empty as a quiet object, or full with branches. About 34 cm." },
  { id: "p-dinner", name: "Dinner Plate", category: "plates", price: 40,
    short: "Coupe plate, glazed to the edge.",
    long: "A coupe dinner plate with a soft, rising rim and no foot ring to catch — glazed cleanly to the edge. Satin white with the faintest warm cast. About 27 cm." },
  { id: "p-side", name: "Side Plate", category: "plates", price: 28,
    short: "For bread, fruit, the small course.",
    long: "The dinner plate's smaller companion, for bread and butter, fruit, or the first course. About 19 cm." },
  { id: "p-coupe", name: "Coupe Plate", category: "plates", price: 34,
    short: "Deep-rimmed plate for pasta and broth.",
    long: "A deeper coupe with a gentle well, between a plate and a shallow bowl — right for pasta, grains, and anything with a little broth. About 23 cm." }
]

seed_to_product = {}
PRODUCTS.each do |p|
  rec = Product.find_or_create_by!(name: p[:name]) do |pr|
    pr.category = cat[p[:category]]
    pr.price = p[:price]
    pr.short = p[:short]
    pr.long_desc = p[:long]
  end
  seed_to_product[p[:id]] = rec
end

SETS = [
  { name: "The Morning Set", price: 92, items: %w[p-morning p-side p-everyday],
    short: "Cup, bowl, and side plate for breakfast.",
    long: "Everything for a slow breakfast for one: the handle-less Morning Cup, an Everyday Bowl, and a Side Plate. A considered price for the three together, boxed in tissue." },
  { name: "Espresso for Two", price: 44, items: %w[p-espresso p-espresso-ribbed],
    short: "A pair of espresso cups, one of each.",
    long: "One plain and one ribbed espresso cup — a pair for two people, or for the contrast of the two forms side by side." },
  { name: "Table for Four", price: 232, items: %w[p-dinner p-dinner p-side p-side p-coupe p-coupe],
    short: "Plates to set the table for guests.",
    long: "A starting table service: two dinner plates, two side plates, and two coupes. Built to be added to over time as your table grows." }
]

SETS.each do |s|
  next if ProductSet.exists?(name: s[:name])
  set = ProductSet.create!(name: s[:name], price: s[:price], short: s[:short], long_desc: s[:long])
  # collapse repeated ids into quantities, preserving first-seen order
  counts = s[:items].each_with_object({}) { |id, h| h[id] = (h[id] || 0) + 1 }
  counts.each_with_index do |(pid, qty), i|
    set.set_items.create!(product: seed_to_product[pid], quantity: qty, position: i)
  end
end

# ---- About ----
about = About.instance
if about.paragraphs.empty?
  about.update!(
    title: "From a small studio, one piece at a time",
    lead: "Preciso is the porcelain studio of Bianna Taynova, working by hand from a sunlit room of benches, shelves, and a single kiln.",
    body: [
      "Every piece begins as fine porcelain, built by hand. I shape, trim, and finish each one, which means small differences travel from my hands into yours — a softened rim, the trace of a brush, a foot left bare. I think of these not as flaws but as the record of how a thing was made.",
      "I work in a quiet palette: white slips, satin and dry-matte glazes, the warm grey of unglazed clay. The forms are meant to disappear into daily life — to be the cup you reach for first, the bowl that holds the morning, the vase for the one stem you brought home.",
      "Pieces are made in small batches and often sell as they leave the kiln. If something you want is gone, write to me and I will tell you when the next firing lands."
    ],
    signature: "Bianna Taynova",
    studio: "Studio Preciso · by appointment"
  )
end

# ---- Seed orders ----
if Order.count.zero?
  p = ->(id) { seed_to_product[id] }
  s = ->(name) { ProductSet.find_by(name: name) }

  o1 = Order.create!(number: "PR-1042", status: "new", total: 160,
    customer_name: "Lena Hofer", customer_email: "lena.hofer@gmail.com",
    customer_phone: "+43 660 1234567", note: "No rush — happy to collect from the studio.",
    created_at: 26.hours.ago)
  o1.order_lines.create!(kind: "product", item_id: p.("p-stem").id, name: "Stem Vase", price: 72, qty: 1)
  o1.order_lines.create!(kind: "product", item_id: p.("p-bud").id, name: "Bud Vase", price: 44, qty: 2)

  o2 = Order.create!(number: "PR-1041", status: "preparing", total: 92,
    customer_name: "Marco Brun", customer_email: "m.brun@outlook.com",
    customer_phone: "+41 79 555 8842", note: "", created_at: 50.hours.ago)
  o2.order_lines.create!(kind: "set", item_id: s.("The Morning Set")&.id, name: "The Morning Set", price: 92, qty: 1)

  o3 = Order.create!(number: "PR-1039", status: "fulfilled", total: 134,
    customer_name: "Sofia Reier", customer_email: "sofia.reier@gmail.com",
    customer_phone: "+43 681 2029384", note: "Gift — please leave the price out.",
    created_at: 96.hours.ago)
  o3.order_lines.create!(kind: "product", item_id: p.("p-hakume").id, name: "Hakume Serving Bowl", price: 58, qty: 1)
  o3.order_lines.create!(kind: "product", item_id: p.("p-morning").id, name: "Morning Cup", price: 38, qty: 2)
end

# ---- Seed believable analytics history (~9 days) ----
if Event.count.zero?
  products = Product.all.to_a
  sets = ProductSet.all.to_a
  cats = Category.all.to_a
  now = Time.current
  rows = []
  rnd = ->(a, b) { a + rand * (b - a) }
  pick = ->(arr) { arr.sample }

  (0..8).to_a.reverse.each do |d|
    day_start = now.beginning_of_day - d.days
    weekend = [ 0, 6 ].include?(day_start.wday)
    sessions = (rnd.(7, 15) * (weekend ? 1.35 : 1) * (d.zero? ? 0.6 : 1)).round
    sessions.times do |si|
      sidv = "seed-#{d}-#{si}"
      tcur = day_start + (rnd.(8, 22) * 3600).seconds
      session_rows = []
      step = lambda do |attrs|
        t = [ now, tcur ].min
        rows << attrs.merge(sid: sidv, occurred_at: t)
        session_rows << attrs.merge(sid: sidv)
        tcur += rnd.(20, 140).seconds
      end

      step.(event_type: "pageview", page_key: "home", label: "Home", piece: false)
      if rand < 0.75
        c = pick.(cats)
        step.(event_type: "pageview", page_key: "shop/#{c.slug}", label: "Shop · #{c.name}", piece: false)
        in_cat = products.select { |pr| pr.category_id == c.id }
        view_n = rnd.(1, [ 3, in_cat.size ].min + 1).floor
        view_n.times do
          pr = pick.(in_cat)
          break unless pr
          step.(event_type: "pageview", page_key: "product/#{pr.id}", label: pr.name, piece: true, name: pr.name)
          step.(event_type: "add_cart", label: pr.name, name: pr.name) if rand < 0.22
        end
      end
      if rand < 0.35 && sets.any?
        set = pick.(sets)
        step.(event_type: "pageview", page_key: "set/#{set.id}", label: set.name, piece: true, name: "#{set.name} (set)")
        step.(event_type: "add_cart", label: set.name, name: set.name) if rand < 0.25
      end
      step.(event_type: "pageview", page_key: "about", label: "About", piece: false) if rand < 0.18

      has_cart = session_rows.any? { |r| r[:event_type] == "add_cart" }
      if has_cart && rand < 0.4
        step.(event_type: "pageview", page_key: "checkout", label: "Checkout", piece: false)
        step.(event_type: "order", label: "PR-#{rnd.(900, 1040).floor}", total: rnd.(24, 240).round) if rand < 0.6
      end
    end
  end

  rows.sort_by! { |r| r[:occurred_at] }
  normalized = rows.map do |r|
    {
      event_type: r[:event_type], sid: r[:sid], page_key: r[:page_key],
      label: r[:label], piece: r.fetch(:piece, false), name: r[:name],
      total: r[:total], occurred_at: r[:occurred_at], created_at: now, updated_at: now
    }
  end
  Event.insert_all(normalized) if normalized.any?
end

puts "Seeded: #{Category.count} categories, #{Product.count} products, #{ProductSet.count} sets, #{Order.count} orders, #{Event.count} events."

# ---- example collection (style group) ----
oro = Collection.find_or_create_by!(slug: "oro") { |c| c.name = "Oro"; c.description = "Pieces finished with a warm, golden cast." }
oro.products = Product.where(category: cat["vases"]).limit(2) + Product.where(category: cat["cups"]).limit(1)
