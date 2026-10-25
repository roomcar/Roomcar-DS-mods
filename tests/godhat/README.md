# Oracle Series checks

Run standalone Lua 5.1 callback tests from the repository root:

```text
lua tests/godhat/run.lua _GodHat--DST
```

18 callback tests cover equipment cleanup, local camera/vision ownership,
recruitment, independent staff bonds, legacy adoption and death/respawn.
The petleash fallback in this unit fixture is simulated.

The persistence and colour-chain engine-selftest directories are disposable server-only test mods.
Enable one alongside Oracle Series in an isolated offline world, never in a
personal world. First launch creates a persistent payload, second launch loads
it; do not run both test mods together.

`persistence-engine-selftest` covers 12 storage stacks, all equipment slots and
wear, native despawn, recruitment, petleash save records and migration admission.
`colour-chain-engine-selftest` covers three independent colours, RPC validation,
three guardians in an open carrying/following chain, nested equipped backpacks,
rejection of paired staves and save cycles, complete native player load and
migration-pet collection, no duplicate guardians, and legacy GUID-based saves
with a paired staff incorrectly stored in its guardian. Legacy conversion must
eject the staff onto nearby land while preserving original guardian contents.

Dev.13 verification passed 47 save + 30 cave reload + 35 surface/legacy reload
engine assertions. Native AnimState colours and follower owners are checked.
UI checks additionally cover native colour-dot geometry, lack of labels, separate
colour RPC, tint updates on inventory icons, controller navigation and cleanup.

Manual acceptance: real host/client UI, reconnect, enter and exit caves, and
multiple players with separate coloured pairs. Native migration admission and
save restoration were verified; real-client portal network transit remains
manual. The staff can be carried by its owner, in a backpack, or by a different
guardian. Open chains are allowed; closed save graphs are rejected.


## Dev.14 effects test

`effects-engine-selftest` is another isolated server-only test mod. Enable it
with Oracle Series instead of either other engine selftest. It checks actual
server action routing and original channelcast animations, the original flute's
one-second application timing, interruption before/after application, completion,
normal panflute/mounted fallback, prediction callbacks/timeouts, native equip
FX and silent equipment reload, first recruitment/renewal/dismissal FX, and
spider/pigman/hound native hit reactions without damage, attacked events or lost
loyalty. Guardian tests cover stock spawn/depart FX, no repeated save/bind effects,
immediate despawn, independent FX lifetime/position, restored health/storage/gear/
colour, and snapshot silence. All 41 assertions passed on game build 759671.
No custom animation, sound or texture media was added. Real-client visual/audio
acceptance still requires playing the test mod. Wearing retains the native hat
equip animation, the Oracle performance uses channelcast_oh, and riding uses
the native instrument action. Special-state creatures can retain their existing
animation rather than being forcibly interrupted.

## Release 1.0.3

The release uses a native 24-unit colour dot (button_icons/circle.tex) in place of the brush. The dot reflects the current pair colour and brightens on focus. The final Lua/UI/recipe/language checks pass. Multiplayer acceptance was explicitly waived by the author for this release. Existing engine evidence above is retained; it is not a claim of new host/client testing. The unused elfmodhat_wht.zip is excluded. Prefab identifiers are unchanged.
