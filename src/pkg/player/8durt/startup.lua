-- Hand-written, not ktox-generated. Runs at computer boot, before any
-- program. Today this just loads the multi-return binding shim so its
-- functions are global by the time a program runs (see ktox-cc-shim.lua).
--
-- v1 of the roadmap's "startup script" item — GitHub-hosted script syncing
-- comes later; see AGENTS.md.

dofile("ktox-cc-shim.lua")
