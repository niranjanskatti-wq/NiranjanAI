# SwarnaCalc – Gold & Jewellery Price Calculator

An installable, **offline-first PWA** for Indian buyers, sellers and jewellers, in `public/swarnacalc/`.
It has no dependencies and no build step, and once it has loaded it works fully offline.

- **Run inside this Next.js app:** `npm run dev` → open <http://localhost:3000/swarnacalc>
- **Run standalone:** serve `public/swarnacalc/` from any static host (e.g. `cd public && python3 -m http.server`) → `/swarnacalc/index.html`
- **Install:** open it in Chrome on Android → *Add to Home screen*. After the first load it runs with no internet.
- **Tests:** `npm test` runs the engine tests with Node's built-in test runner.

### Formula (shown step by step in the app)

```
Net weight        = Gross − Stone weight
Chargeable weight = Net + Wastage (VA: % of net, or fixed grams)
Metal value       = Chargeable × Rate (rate for the purity, or 24K rate × purity ÷ 99.9)
Making            = ₹/g × net (or chargeable) wt  |  % of metal value  |  flat ₹   (− making discount)
Subtotal          = Metal + Making + Stones + Hallmark + Other − Discount on total
GST               = Σ component × its GST %  (default 3% on metal, making, hallmark; editable per component)
Total             = Subtotal + GST, rounded (none / ₹1 / ₹10)
Old gold          = weight × tested purity × (1 − melting loss %) × buyback rate, deducted AFTER GST
```

All arithmetic uses exact BigInt decimals (`js/decimal.js`), so there are no floating-point errors. Weights are kept to 3 decimals and money to paise.

**Worked example** (this is a test case in `tests/swarnacalc.test.mjs`): 22K, gross 10 g, stone 0.5 g, rate ₹6,800/g for 22K, wastage 8%, making ₹500/g, hallmark ₹45, GST 3%

| Step | Calculation | Result |
|---|---|---|
| Net weight | 10.000 − 0.500 | 9.500 g |
| Wastage | 8% × 9.500 | 0.760 g |
| Chargeable | 9.500 + 0.760 | 10.260 g |
| Metal value | 10.260 × ₹6,800 | ₹69,768.00 |
| Making | 9.500 g × ₹500 | ₹4,750.00 |
| Hallmark | ₹45 × 1 | ₹45.00 |
| Subtotal | | ₹74,563.00 |
| GST 3% | metal ₹2,093.04 + making ₹142.50 + hallmark ₹1.35 | ₹2,236.89 |
| Before rounding | | ₹76,799.89 |
| **Final total** | rounded to nearest ₹1 | **₹76,800** |

### Features

- **Modes:** Buy, Sell old gold, Exchange, Coin/Bar, and Budget (reverse calculation: how many grams a budget buys). Estimates can hold multiple items.
- **Units:** g / mg / tola (tola size is editable, 11.664 g by default). Stone weight can also be entered in carats.
- **Validation:** for example, stone weight must be less than gross weight. Numbers must be valid and percentages must be 0–100.
- **Settings:** everything can be added, edited or deleted. This covers default rates, GST per component, making, wastage, hallmark, presets, metals and purities, categories, the shop profile (logo, GSTIN), rounding, Indian number format, language (English / ಕನ್ನಡ / हिन्दी), dark or light theme, font size, and which fields to show or hide.
- **Sharing:** WhatsApp text with selectable fields (Web Share API, falling back to wa.me), a gold-and-black image card, and a PDF estimate with an itemised table. All three are generated on the device.
- **History (IndexedDB):** search, filter by date and mode, edit, duplicate, delete and share saved estimates. You can back up and restore everything as JSON.
- **Compare:** up to 3 jewellers' quotes side by side, with the cheapest highlighted.
- **Rates:** today's rates per purity, other purities filled in from the 24K rate, and a rate-history chart.
- **Optional online features** (the calculator never waits on these):
  - Bill-photo scan through Claude (uses your own API key, stored only on the device).
  - Voice input in English, Kannada and Hindi.
  - A live-rate fetch from a JSON URL you configure. It always asks "use this rate?" first.
- **Fair-price check:** works offline. It flags making or wastage that is higher than your limits or presets.

| File | Purpose |
|---|---|
| `js/decimal.js` | exact decimal math + Indian number formatting |
| `js/engine.js` | calculation engine, validation, reverse calc, fair-price check |
| `js/config.js` | default settings, metals, purities, presets |
| `js/app.js` | UI, views, bindings |
| `js/share.js` | WhatsApp text, image card, PDF writer |
| `js/store.js` | IndexedDB storage, backup/restore |
| `js/i18n.js` | translations (add a language by adding a dictionary) |
| `js/ai.js` | voice parser, Claude bill scan, live rate |
| `sw.js` | service worker (precaches the whole app) |

---

This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
