# 🏝️ ISLPOAP — the island where POAPs live on

**Live:** https://islpoap.xyz — *IStill Love Poap* 🏝️
(mirror: https://shakaleikaumaka.github.io/islpoap/)

A free, open-source, CC0 **proof-of-presence badge forge** built on
[BasePaint](https://basepaint.xyz) — a love hack dedicated to **Patricio Worthalter,
Isabel González, and the whole POAP team**, who spent five years turning
*"I was there"* into something you could keep forever.

POAP was born at ETHDenver 2019 and minted **6.7 million** attestations of presence
before entering maintenance mode in March 2026. The badges remain. The love remains.
This island marries POAP's heart with BasePaint's hands:

> **Every BasePaint day is an event. Everyone who painted was there. The chain remembers.**

Built for the **BasePaint Year 3 Hackathon**, from the official
[basepaint-starter](https://github.com/zherring/basepaint-starter).

---

## What it does

One HTML file. Zero dependencies. No backend, no keys, no kill switch.

| Room | What happens |
|---|---|
| 🏝️ **Today's Island** | The live badge **paints itself** — today's canvas is reconstructed *pixel-by-pixel from the raw on-chain stroke firehose* (BasePaint GraphQL indexer), set into a POAP-style badge, refreshed every 30s. Not a screenshot — a replay of the chain. |
| ⚒ **Badge Forge** | Pick any of BasePaint's 1000+ days → its CC0 artwork, theme and palette are forged into a POAP-style keepsake badge (palette bead ring, arc text). Download the PNG and an **ERC-1155-ready metadata JSON**. Free, forever. |
| 🔍 **Proof of Paint** | Enter any address → every day it painted, with pixels placed — its attendance record on the island. (EIP-55 checksumming done client-side with an inlined keccak256, because the indexer's filters are case-sensitive.) |
| 🌺 **The Memorial** | Enter any address → all its **real POAPs**, alive on Gnosis, Base, Celo, Linea, Chiliz, Mantle, Unichain… Nothing is gone. That was the whole point. |
| 📖 **Lore** | The story of POAP, the dedication, the covenant, the roadmap. |

## The covenant (the CROPS mandate)

- 🌱 **Free forever.** No fees, no token, no skim, no referral cut taken. Zero extraction.
- 🌱 **CC0 & open source.** The art is public domain (thank you, BasePaint). The code is yours to fork.
- 🌱 **No backend.** One static file reading public infrastructure — it cannot be shut down, only forked.
- 🌱 **Dedicated.** To the POAP team. Mahalo. 🤙🌺

## Judging axes, honestly

- **Usefulness** — a working badge generator for artists & event organizers; a per-address
  BasePaint attendance explorer; a POAP collection viewer that still works after the shutdown.
- **Craft** — canvas reconstruction from raw stroke data (`x,y,colorIndex` triplets), live
  30s repaint, EIP-55 via inlined keccak, BasePaint design system (colors, Roboto Mono,
  `image-rendering: pixelated`), CORS-only public APIs, cursor pagination.
- **Originality** — nobody else is treating BasePaint days as *events* and painters as
  *attendees*. POAP × BasePaint is a marriage, not a mashup.
- **Staying power** — static + CC0 + MIT + no server = unkillable; plus a staged on-chain
  Phase 2 (below) so badges can outlive even this page.

## Roadmap — POAP on every chain

1. **Phase 1 ✓ LIVE** — the forge, the proof, the memorial.
2. **Phase 2 ✓ BUILT, igniting** — [`contracts/ISLPOAP.sol`](contracts/ISLPOAP.sol): a free-claim
   ERC-1155 on Base. Token id = BasePaint day; once per address per day, gas only. **No owner, no
   admin keys, no fees — and metadata is generated fully on-chain (base64 JSON)**, so badges outlive
   every server. Compiled (solc 0.8.28, viaIR) and fully rehearsed on anvil (claim / double-claim
   rejection / day gating / transfers / batch / ERC-165 / metadata decode — all green). Deploys the
   moment the deploy wallet holds a dust of Base ETH.
3. **Phase 3 ✓ LIVE** — the **Drop Maker**: name your moment, pick a CC0 day as badge art, share one
   link. The whole drop is encoded inside the URL — no backend, no signup, no cost. Guests keep the
   badge and claim it on Base. The way POAP always felt.

## Run it

```bash
python3 -m http.server 8000   # or just open index.html
```

## APIs used (all public, all CORS-open)

- `https://basepaint.xyz/api/theme/{day}` — theme, palette, size
- `https://basepaint.net/v3/{day}.png` — finished CC0 artwork
- `https://graphql.basepaint.xyz` — strokes, contributions, canvas stats
- `https://frontend.poap.tech/actions/scan/{address}` — POAP collections (still alive 💛)

## License

Code **MIT**. Artwork **CC0** (BasePaint). Inlined
[js-sha3](https://github.com/emn178/js-sha3) © Chen, Yi-Cyuan, MIT.

---

*"One special gift Patricio gave me was upgrading my flight home from Argentina — it meant
the world to sleep after the show and make it to Thanksgiving with my family. I want POAP
to live on, on every chain. This is a gift, not extractive."*
— **Shaka Lei Kaumaka** 🤙🌺, keeper of ~100 POAPs and counting

Built with ♥ by Shaka's agent ʻohana.
