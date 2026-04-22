# CHANGELOG

<!-- version list -->

## v1.11.6 (2026-04-22)

### Bug Fixes

- **lua**: Add bounds check to sync_all_cells to prevent save crash
  ([`b3c9abe`](https://github.com/ansh-info/ipynb.nvim/commit/b3c9abee90abbde48e1456cd52072da118a62b2e))

- **lua**: Format sync bounds warning for stylua compliance
  ([`98b1176`](https://github.com/ansh-info/ipynb.nvim/commit/98b11762a50fd7228625ef7435c2696f050d4d90))

- **lua**: Format sync bounds warning for stylua compliance
  ([`ac85c6d`](https://github.com/ansh-info/ipynb.nvim/commit/ac85c6d03cdd719c66aa20bd5e3f463646f921bd))

- **lua**: Warn instead of silent skip when sync index is out of range
  ([`7dffc29`](https://github.com/ansh-info/ipynb.nvim/commit/7dffc29e02649a41f326679bd025d77d27356b7b))


## v1.11.5 (2026-04-22)

### Bug Fixes

- **lua**: Use buffer-only arg in FileType autocmd to avoid pattern conflict
  ([`2de02a6`](https://github.com/ansh-info/ipynb.nvim/commit/2de02a6c7910ec630c3250208f29ffa358f7798a))


## v1.11.4 (2026-04-22)

### Bug Fixes

- **lua**: Preserve LSP omnifunc when LSP client is attached
  ([`13f0a7b`](https://github.com/ansh-info/ipynb.nvim/commit/13f0a7bcc4cfe76063da25a851111903fe71aece))

- **lua**: Target correct buffer in LSP FileType autocmd and set filetype early
  ([`4129100`](https://github.com/ansh-info/ipynb.nvim/commit/4129100ce9d6bdfd90f7d1ffa26da7f326757b56))


## v1.11.3 (2026-04-22)

### Bug Fixes

- **lua**: Export push_undo from cell module for execution undo
  ([`5365fa8`](https://github.com/ansh-info/ipynb.nvim/commit/5365fa8147bc8e4d3653efd4ea1d5311915ef01b))

- **lua**: Snapshot undo before cell execution for output revert
  ([`0e1ee1c`](https://github.com/ansh-info/ipynb.nvim/commit/0e1ee1cb1097bc0561e3a99cca1af4203d189331))


## v1.11.2 (2026-04-22)

### Bug Fixes

- **lua**: Seed math.randomseed in setup for unique cell IDs
  ([`2955ef2`](https://github.com/ansh-info/ipynb.nvim/commit/2955ef262af7bf7866efe116e673f86db5e016bf))


## v1.11.1 (2026-04-21)

### Bug Fixes

- **lua**: Correct indent assertion in pretty-print JSON test
  ([`69468fa`](https://github.com/ansh-info/ipynb.nvim/commit/69468fa2f054d3795832e915a573ff3436278b63))

- **lua**: Emit null instead of NaN/Infinity in json_encode_pretty
  ([`132f0d6`](https://github.com/ansh-info/ipynb.nvim/commit/132f0d6e8d79ea2df1010daed8efe188ba19ec4a))

- **lua**: Use vim.empty_dict() for empty metadata in save
  ([`69d2f64`](https://github.com/ansh-info/ipynb.nvim/commit/69d2f6488b7710ec277d201804148b06555c9b7c))

### Testing

- **lua**: Add spec for NaN/Infinity null encoding in save
  ([`e95dfd6`](https://github.com/ansh-info/ipynb.nvim/commit/e95dfd66cf53c152095bd07ba5d1af0170338e5f))


## v1.11.0 (2026-04-20)

### Bug Fixes

- **lua**: Use line-based assertions in pretty-print JSON tests
  ([`0e32bbc`](https://github.com/ansh-info/ipynb.nvim/commit/0e32bbc126c1952dc8ee3ec257a4a1afa01a7d0b))

### Continuous Integration

- **config**: Add Python syntax check and headless test jobs
  ([`7515579`](https://github.com/ansh-info/ipynb.nvim/commit/7515579ae2393a610ead0a693777058a3509c941))

### Features

- **lua**: Pretty-print saved .ipynb JSON for git-friendly diffs
  ([`fa405b8`](https://github.com/ansh-info/ipynb.nvim/commit/fa405b887c2136714827450db385ffbb6b063f45))

### Refactoring

- **lua**: Remove dead code from utils.lua
  ([`386f30f`](https://github.com/ansh-info/ipynb.nvim/commit/386f30f3a6808f991ce62420017123669f0bc64c))

### Testing

- **lua**: Add specs for pretty-print JSON output format
  ([`379566e`](https://github.com/ansh-info/ipynb.nvim/commit/379566eb963bb260cdc75342ee37596cc416bb72))

- **lua**: Remove specs for deleted utils functions
  ([`b972eb9`](https://github.com/ansh-info/ipynb.nvim/commit/b972eb907e4b52ba5da54e334dfe1bc321d36286))


## v1.10.3 (2026-04-19)

### Bug Fixes

- **lua**: Add smart undo/redo keymaps and sync-before-rerender
  ([`893ab01`](https://github.com/ansh-info/ipynb.nvim/commit/893ab01de4d8ebe4dd6179f50cf4930852d69743))

- **lua**: Apply stylua formatting to cell.lua
  ([`cc26b42`](https://github.com/ansh-info/ipynb.nvim/commit/cc26b425060d74a2970b41bf560af18f0a0d34df))

- **lua**: Implement notebook-level undo for structural cell operations
  ([`c2d1129`](https://github.com/ansh-info/ipynb.nvim/commit/c2d1129634692e3d6a9353275bc9118bb620a126))

### Documentation

- **docs**: Add smart undo/redo keymaps to README
  ([`a080c9f`](https://github.com/ansh-info/ipynb.nvim/commit/a080c9fa587ff884de5c2bd89ece3782e8c2484f))

- **docs**: Update CLAUDE.md undo architecture and session notes
  ([`417ae65`](https://github.com/ansh-info/ipynb.nvim/commit/417ae6597891c563c351c966c3e5abb927104117))

### Testing

- **lua**: Add assertions for notebook undo/redo public API
  ([`cbd7f5e`](https://github.com/ansh-info/ipynb.nvim/commit/cbd7f5eeb6458adf28d97e25080a8f6509460c4c))


## v1.10.2 (2026-04-18)

### Bug Fixes

- **lua**: Migrate deprecated nvim_buf_set_option in inspector
  ([`1c05559`](https://github.com/ansh-info/ipynb.nvim/commit/1c05559a81e0ed37e80863623cfd9f60f84dfbbc))

- **lua**: Migrate deprecated nvim_buf_set_option in keymaps
  ([`252c23c`](https://github.com/ansh-info/ipynb.nvim/commit/252c23c3b41ac68b8fd6a5ee4b6a682256e59195))

- **lua**: Reduce omnifunc timeout and migrate deprecated API
  ([`c9a59c5`](https://github.com/ansh-info/ipynb.nvim/commit/c9a59c53f6d45f72da2ac570425d833b92f204cf))

- **lua**: Remove render-markdown.nvim integration that applies to whole buffer
  ([`81103e2`](https://github.com/ansh-info/ipynb.nvim/commit/81103e20ebced1d156fdf57abc0d6eec17a2d512))

- **python**: Wire connection_dir config to find_connection_file
  ([`80cbd03`](https://github.com/ansh-info/ipynb.nvim/commit/80cbd03b76d9680a5209cf051c403982764d747f))

### Documentation

- **docs**: Remove render-markdown.nvim from optional dependencies
  ([`39233bc`](https://github.com/ansh-info/ipynb.nvim/commit/39233bc168c3f3979f1aa6f1e9a9dafec5a0c783))


## v1.10.1 (2026-04-17)

### Bug Fixes

- **lua**: Apply stylua formatting to kernel/init.lua
  ([`460e151`](https://github.com/ansh-info/ipynb.nvim/commit/460e151cfc87ba4f946aae56b3efc905af0e6806))

- **lua**: Migrate deprecated APIs and add BufWinEnter window options
  ([`9e8dc08`](https://github.com/ansh-info/ipynb.nvim/commit/9e8dc08eca3529f7da2d2150e50f949e4b9cbde4))

- **lua**: Migrate deprecated APIs and consolidate cell ID generation
  ([`a50ddf4`](https://github.com/ansh-info/ipynb.nvim/commit/a50ddf49cd8562ad639a88f417898806c423325e))

- **lua**: Migrate vim.loop to vim.uv and add auto-start retry limit
  ([`be5b4fc`](https://github.com/ansh-info/ipynb.nvim/commit/be5b4fcbf1f66466b0995b25343a0015d142303e))

- **lua**: Preserve nbformat_minor from parsed notebook and export gen_cell_id
  ([`24ad2a3`](https://github.com/ansh-info/ipynb.nvim/commit/24ad2a37c09a8c90c589db4eaeec01bcef0a3556))

- **python**: Send interrupt via control channel for attached kernels
  ([`d37ebf0`](https://github.com/ansh-info/ipynb.nvim/commit/d37ebf0969979ba46c89d3c0544252ca22bdc596))

### Documentation

- **docs**: Add missing keymaps, commands, and config to README
  ([`2afc8b0`](https://github.com/ansh-info/ipynb.nvim/commit/2afc8b079627d4f90c7a99b4f7a386f250d1ecea))

- **docs**: Sync CLAUDE.md file tree and module paths with codebase
  ([`9372efa`](https://github.com/ansh-info/ipynb.nvim/commit/9372efa8363be7ee39b2dce9f6fb2ed7fd110f02))


## v1.10.0 (2026-04-15)

### Bug Fixes

- **lua**: Remove hardcoded python filetype and fix LSP attachment
  ([`8d9fd64`](https://github.com/ansh-info/ipynb.nvim/commit/8d9fd6469c7c2d88b43f918a76ff2fcaebba7d3a))

- **lua**: Set buffer filetype from notebook kernel language in render
  ([`f131750`](https://github.com/ansh-info/ipynb.nvim/commit/f131750f61a9588d4865894d31b6d5143ce06da4))

### Features

- **lua**: Add notebook_language() to derive filetype from metadata
  ([`905334c`](https://github.com/ansh-info/ipynb.nvim/commit/905334cc7f644c98f33dc0ad295e02ed4d94e9b6))


## v1.9.10 (2026-04-15)

### Bug Fixes

- **lua**: Clean up image temp files and output state on BufDelete
  ([`5fa5a5a`](https://github.com/ansh-info/ipynb.nvim/commit/5fa5a5aa23fa3f8c928ffb037187fd9e8404312a))


## v1.9.9 (2026-04-14)

### Bug Fixes

- **lua**: Use buffer window width instead of focused window for borders
  ([`5a23844`](https://github.com/ansh-info/ipynb.nvim/commit/5a2384402490c8e910300812de69f99140187afa))


## v1.9.8 (2026-04-14)

### Bug Fixes

- **lua**: Add crash count limit to kernel auto-restart to prevent infinite loop
  ([`e882161`](https://github.com/ansh-info/ipynb.nvim/commit/e88216117a2578b6d7036eb3740d826651b7a35a))


## v1.9.7 (2026-04-13)

### Bug Fixes

- **lua**: Preserve existing cmp sources when adding ipynb kernel source
  ([`e38ad69`](https://github.com/ansh-info/ipynb.nvim/commit/e38ad69721f1ae7ab3f3e27fd122d4577a0d1c1a))


## v1.9.6 (2026-04-12)

### Bug Fixes

- **lua**: Remove WinResized handler that wiped undo tree on every resize
  ([`db06a45`](https://github.com/ansh-info/ipynb.nvim/commit/db06a45698afbd258867e6f94cc6b34a032ba8f7))


## v1.9.5 (2026-04-12)

### Bug Fixes

- **lua**: Set conceallevel=2 and target correct window for notebook buffers
  ([`1d94eb3`](https://github.com/ansh-info/ipynb.nvim/commit/1d94eb34bfb0d85e5334f55fedee4b4c02ca0990))


## v1.9.4 (2026-04-11)

### Bug Fixes

- **lua**: Deduplicate kernel ready notification with deferred fallback
  ([`76c121d`](https://github.com/ansh-info/ipynb.nvim/commit/76c121d4a848c2b803fbe1306349386b8bd69ddb))


## v1.9.3 (2026-04-10)

### Bug Fixes

- **lua**: Handle empty notebook in add cell commands
  ([`61dbc13`](https://github.com/ansh-info/ipynb.nvim/commit/61dbc13106e552febf9bde14f543a699e44b62d3))

- **lua**: Handle empty notebook in add cell keymaps
  ([`8bbc81b`](https://github.com/ansh-info/ipynb.nvim/commit/8bbc81b85f8127bce15a227bcdee0b11f2660237))


## v1.9.2 (2026-04-10)

### Bug Fixes

- **lua**: Clamp help overlay dimensions to terminal size
  ([`ad9e311`](https://github.com/ansh-info/ipynb.nvim/commit/ad9e3119e25888644b70a80b26f8e9bf5c0163e3))

- **lua**: Clamp kernel info window dimensions to terminal size
  ([`3613aa0`](https://github.com/ansh-info/ipynb.nvim/commit/3613aa0a1974ea8b6785844c832b267b5437f318))


## v1.9.1 (2026-04-10)

### Bug Fixes

- **lua**: Add missing IpynbRunBelow and IpynbKernelAttach commands
  ([`f8e7c08`](https://github.com/ansh-info/ipynb.nvim/commit/f8e7c080aec1b50f69e38f6849a64aeb0a51803a))


## v1.9.0 (2026-04-09)

### Documentation

- **docs**: Document split/merge commands and missing keymaps in README
  ([`9f90358`](https://github.com/ansh-info/ipynb.nvim/commit/9f903584d751135c5d1bea280760247727779097))

### Features

- **config**: Add split_cell and merge_cell keymap options
  ([`1ae9bef`](https://github.com/ansh-info/ipynb.nvim/commit/1ae9befca979100e63c3cdd451c80284c84475b4))

- **lua**: Add IpynbCellSplit and IpynbCellMerge user commands
  ([`ecc6d44`](https://github.com/ansh-info/ipynb.nvim/commit/ecc6d44c1d9e409b990faa26d6bcb62c733f3839))

- **lua**: Add split_cell and merge_cell_below operations
  ([`21e50ba`](https://github.com/ansh-info/ipynb.nvim/commit/21e50bad60015d8dce878a192bfd1819c2fca3ee))

- **lua**: Wire split_cell and merge_cell keymaps and help overlay
  ([`036ba78`](https://github.com/ansh-info/ipynb.nvim/commit/036ba788f4b84a1a0dd2df5a38e192b3c58037ca))


## v1.8.0 (2026-04-09)

### Features

- **lua**: Add ANSI SGR escape sequence parser
  ([`5739d28`](https://github.com/ansh-info/ipynb.nvim/commit/5739d28362aa7198fe5fc71d149635ef20519cfc))

- **lua**: Integrate ANSI parser into kernel output rendering
  ([`b212b47`](https://github.com/ansh-info/ipynb.nvim/commit/b212b4791bbab79ccd83a42df16a0403ddccf5f7))

- **python**: Preserve ANSI color codes in kernel output
  ([`a7555ae`](https://github.com/ansh-info/ipynb.nvim/commit/a7555aec47de2f9b5aa3c333470ef8b23d573269))


## v1.7.0 (2026-04-07)

### Documentation

- **docs**: Add statusline section with lualine and heirline examples
  ([`f67b916`](https://github.com/ansh-info/ipynb.nvim/commit/f67b916a3bbe8d95f641a9c80f46e9f28bd6607d))

### Features

- **lua**: Add statusline() and statusline_hl() public API
  ([`b3a58cb`](https://github.com/ansh-info/ipynb.nvim/commit/b3a58cb737b1390ad1faede8e930aa9a72679f20))

- **lua**: Expose kernel_name() getter on kernel module
  ([`45887d0`](https://github.com/ansh-info/ipynb.nvim/commit/45887d05cf25977d33bb60d61fc917bae415eeba))


## v1.6.7 (2026-04-07)

### Bug Fixes

- **lua**: Prevent duplicate buffer open for same notebook file
  ([`55dc2d5`](https://github.com/ansh-info/ipynb.nvim/commit/55dc2d5c8763c50061206d3fc418ffbe8d39bf16))


## v1.6.6 (2026-04-05)

### Bug Fixes

- **lua**: Filter LSP diagnostics out of markdown cell ranges
  ([`16b4487`](https://github.com/ansh-info/ipynb.nvim/commit/16b4487885d0e332b2e09977b317732843882eae))

- **lua**: Restrict Python treesitter to code cell ranges
  ([`7756eb2`](https://github.com/ansh-info/ipynb.nvim/commit/7756eb2f801d197c50a7ede8b8f7cd4e90284cb0))


## v1.6.5 (2026-04-05)

### Bug Fixes

- **config**: Add restart_on_crash kernel option
  ([`5be35a5`](https://github.com/ansh-info/ipynb.nvim/commit/5be35a53c81e9be84c5a6432510317be00d98905))

- **lua**: Fix kernel crash recovery and add restart_on_crash option
  ([`8c65cfc`](https://github.com/ansh-info/ipynb.nvim/commit/8c65cfc8555c50870c3c5c166f8ed66e8c091f4c))


## v1.6.4 (2026-04-05)

### Bug Fixes

- **lua**: Re-render borders on WinEnter when window width changes
  ([`3f800de`](https://github.com/ansh-info/ipynb.nvim/commit/3f800de735ba0480e0d1e5fdcfb919d59558d74b))


## v1.6.3 (2026-04-05)

### Bug Fixes

- **lua**: Preserve undo history across structural cell operations
  ([`3d8d5e0`](https://github.com/ansh-info/ipynb.nvim/commit/3d8d5e03753ecddc5a66c8467b4ed5e52972ea65))

- **lua**: Preserve undo history on VimResized re-render
  ([`65d8f6a`](https://github.com/ansh-info/ipynb.nvim/commit/65d8f6a0c0af00c99a81bb92ff2a49ce04b1ec02))


## v1.6.2 (2026-04-03)

### Bug Fixes

- **lua**: Clean up stale output/image refs before render and add render hooks
  ([`38cbb9c`](https://github.com/ansh-info/ipynb.nvim/commit/38cbb9c43ad709e472da086fdf0177473b1fa0f6))

- **lua**: Remap kernel pending cell_state refs after render, guard nil cell
  ([`64f179c`](https://github.com/ansh-info/ipynb.nvim/commit/64f179c9f026db65db9e43c631c3796b800879b0))


## v1.6.1 (2026-04-03)

### Performance Improvements

- **lua**: Limit sync_sources_from_buf to active cell on keystrokes
  ([`7af09e0`](https://github.com/ansh-info/ipynb.nvim/commit/7af09e0a2fe93accbe9114f61d1c39f5bb0b41f0))

- **lua**: Pass active cell index to reanchor and sync on TextChanged
  ([`493940b`](https://github.com/ansh-info/ipynb.nvim/commit/493940b1d527b1b43b7adbaf29df832df2a4e126))


## v1.6.0 (2026-04-03)

### Features

- **config**: Add keymap defaults for new cell operations
  ([`cf477aa`](https://github.com/ansh-info/ipynb.nvim/commit/cf477aa8c3f1e79ca6c3d3c53bc27385d87e4ddf))

- **lua**: Add :Ipynb* user commands for new cell operations
  ([`fb1fc7a`](https://github.com/ansh-info/ipynb.nvim/commit/fb1fc7a8a64a5b86814834c6d2d33e02114119e3))

- **lua**: Add keymaps and help overlay entries for new cell operations
  ([`2f6e15e`](https://github.com/ansh-info/ipynb.nvim/commit/2f6e15ebae01565c1dd520c3dbfcd2281b37edf3))

- **lua**: Add move, duplicate, yank/paste, toggle cell type operations
  ([`0b87ce6`](https://github.com/ansh-info/ipynb.nvim/commit/0b87ce65da1c7a0071d413c4bf5b5bb72b510ee8))


## v1.5.1 (2026-04-02)

### Bug Fixes

- **lua**: Disable undo during render() to prevent buffer corruption
  ([`72ad413`](https://github.com/ansh-info/ipynb.nvim/commit/72ad4130ed10cfb8da256f39c029f1fe2367336a))


## v1.5.0 (2026-04-01)

### Chores

- **config**: Add syntax = "Lua52" to stylua config
  ([`050dee6`](https://github.com/ansh-info/ipynb.nvim/commit/050dee6d6f3e3cf83fec525d12ef97ad9de7a155))

- **config**: Remove dead backend field from ImageConfig
  ([`909df5e`](https://github.com/ansh-info/ipynb.nvim/commit/909df5e1d30b03ed1473bd6c73085f631e5c137b))

- **config**: Revert syntax = "Lua52" from stylua config
  ([`28655ac`](https://github.com/ansh-info/ipynb.nvim/commit/28655ac42a54a0a93ccc4f6de3e0a4036d08401e))

- **lua**: Remove stale render_stacked and magick_cli comments
  ([`36c3c20`](https://github.com/ansh-info/ipynb.nvim/commit/36c3c20196c4be1b5735e7c4ce868e468f775138))

- **lua**: Remove WinScrolled rerender and on_lines stale-image guard
  ([`d27208d`](https://github.com/ansh-info/ipynb.nvim/commit/d27208d1c2959a997063aaebda0fc6389ea509a5))

- **lua**: Update init.lua comment to reference snacks.nvim
  ([`94e7c99`](https://github.com/ansh-info/ipynb.nvim/commit/94e7c99e0fab14d64b1d48c6d1da95c82748a022))

- **lua**: Update output.lua for snacks image backend
  ([`6b43e24`](https://github.com/ansh-info/ipynb.nvim/commit/6b43e2413e80e33c6eb6369a3507f2dca4d1f308))

### Documentation

- Replace image.nvim with snacks.nvim, remove ImageMagick requirement
  ([`4f518ed`](https://github.com/ansh-info/ipynb.nvim/commit/4f518ed2d92b7d041fd72f60b404dd381b34c64b))

- **docs**: Update CLAUDE.md for snacks.nvim migration
  ([`280e5ca`](https://github.com/ansh-info/ipynb.nvim/commit/280e5cad365e63b85fa7fa94591c7817365e91af))

- **docs**: Update CONTRIBUTING.md layout for snacks.nvim migration
  ([`9937fdf`](https://github.com/ansh-info/ipynb.nvim/commit/9937fdf39597ab9d3f8b3bf3c78f70ceba2ad7e4))

### Features

- **lua**: Add :checkhealth ipynb provider
  ([`d93038b`](https://github.com/ansh-info/ipynb.nvim/commit/d93038bb02a90146de6b259c2cc41bdabce09623))

- **lua**: Rewrite image rendering using snacks.nvim placements
  ([`208d14b`](https://github.com/ansh-info/ipynb.nvim/commit/208d14b7ae93d87b81fb0b7d5876835077fad4a0))

- **plugin**: Register :checkhealth ipynb and :IpynbHealth command
  ([`a59178d`](https://github.com/ansh-info/ipynb.nvim/commit/a59178d0c2279bdface74b17ed940f42bbb59a57))

### Refactoring

- **lua**: Replace goto/label with if-guards in image.lua
  ([`23abac5`](https://github.com/ansh-info/ipynb.nvim/commit/23abac52234a117347a0c7a7019c3a8be75dd9bf))


## v1.4.11 (2026-03-31)

### Bug Fixes

- **lua**: Add clear_stale() to remove images with invalid buffer row
  ([`7088106`](https://github.com/ansh-info/ipynb.nvim/commit/7088106320265bfd5919dea7ca73e65d91ec8bc9))

- **lua**: Use nvim_buf_attach on_lines to clear stale images before undo crash
  ([`6ca72c6`](https://github.com/ansh-info/ipynb.nvim/commit/6ca72c60a47c08d34b2b5e32dfdd3e1a8ab80cfb))


## v1.4.10 (2026-03-31)

### Bug Fixes

- **lua**: Skip image re-render when screen row unchanged
  ([`479601e`](https://github.com/ansh-info/ipynb.nvim/commit/479601ec9e33e48df3b0f435875354e795e06c7d))


## v1.4.9 (2026-03-31)

### Bug Fixes

- **lua**: Add 16px transparent gap between stacked images
  ([`9bc3688`](https://github.com/ansh-info/ipynb.nvim/commit/9bc368880ce4363162c2ad85c94b55060b8e4f02))


## v1.4.8 (2026-03-31)

### Bug Fixes

- **lua**: Use pattern=python with double vim.schedule for LSP attach
  ([`d033625`](https://github.com/ansh-info/ipynb.nvim/commit/d033625a83017476f95d80f536d27c2463cfed67))


## v1.4.7 (2026-03-31)

### Bug Fixes

- **lua**: Call render_stacked with chunk list instead of indexed renders
  ([`f43af4b`](https://github.com/ansh-info/ipynb.nvim/commit/f43af4b632fe0fbed51b8e7ab7914a09954aeaa9))

- **lua**: Combine multiple images vertically before rendering
  ([`1d449de`](https://github.com/ansh-info/ipynb.nvim/commit/1d449dec4fadf8de0062c01a06a5e66957c0c333))

- **lua**: Defer cursor placement after add_cell to avoid snap jump
  ([`a90b7b0`](https://github.com/ansh-info/ipynb.nvim/commit/a90b7b0140503957f6d643cfda2bdba3ab13c81f))

- **lua**: Use buf=bufnr in exec_autocmds to fix LSP not attaching
  ([`27121bb`](https://github.com/ansh-info/ipynb.nvim/commit/27121bbcd4c7a7cff97820804b27530767fac157))


## v1.4.6 (2026-03-31)

### Bug Fixes

- **lua**: Extend _active guard to cover nested image schedule
  ([`cf7cd8a`](https://github.com/ansh-info/ipynb.nvim/commit/cf7cd8aadfd17ce63b19c61ed6ad6e40e73c49e6))

- **lua**: Mark buffer modified when cell outputs are written to notebook model
  ([`3d1c66b`](https://github.com/ansh-info/ipynb.nvim/commit/3d1c66b9f3989089932e50a8c3a4e02b8e235d9c))


## v1.4.5 (2026-03-31)

### Bug Fixes

- **lua**: Stack multiple images vertically using img_index offset
  ([`764a43b`](https://github.com/ansh-info/ipynb.nvim/commit/764a43b61748c13ccd71a4cac709db253e2b31a9))

- **lua**: Track per-image index in output renderer for vertical stacking
  ([`12b1a89`](https://github.com/ansh-info/ipynb.nvim/commit/12b1a898a8b4aa2eadde9d3cb73ee3e0e6c4f616))

### Testing

- Add multi-image cell to test notebook for vertical stacking
  ([`5c9c756`](https://github.com/ansh-info/ipynb.nvim/commit/5c9c756fe4b51b342b49612c2ca61a0abc4cd38b))


## v1.4.4 (2026-03-30)

### Bug Fixes

- **lua**: Add nested vim.schedule for image rendering to fix invisible-until-scroll bug
  ([`0ed6bb4`](https://github.com/ansh-info/ipynb.nvim/commit/0ed6bb4432da0a8ef76aab924b2568ca5cea7c48))

- **lua**: Suppress text/plain result when image present in nb_output_to_chunks
  ([`c9de0bd`](https://github.com/ansh-info/ipynb.nvim/commit/c9de0bd18dc5130b3d433fcebf41c6708386867d))

- **lua**: Use nvim_buf_call to ensure correct buffer context for LSP attach
  ([`133519f`](https://github.com/ansh-info/ipynb.nvim/commit/133519f0874cbbc93cf5c820a1a9054b87b5dc37))

- **python**: Suppress text/plain when image MIME is present in same output
  ([`be77d0e`](https://github.com/ansh-info/ipynb.nvim/commit/be77d0e85691e672b2475d272cccefff6dc746cd))


## v1.4.3 (2026-03-30)

### Bug Fixes

- **lua**: Remove spacer virt_lines and nested schedule from output renderer
  ([`23c90a6`](https://github.com/ansh-info/ipynb.nvim/commit/23c90a64820c6d099dac4c1adfcf5ef5becc0e9b))

- **lua**: Replace float windows with separator-line positioning for images
  ([`2286311`](https://github.com/ansh-info/ipynb.nvim/commit/22863115e715a0097e600bc36774f9df097af0ef))


## v1.4.2 (2026-03-30)

### Bug Fixes

- **lua**: Pass text virt_line offset to image.render and add spacer lines
  ([#84](https://github.com/ansh-info/ipynb.nvim/pull/84),
  [`7850e4b`](https://github.com/ansh-info/ipynb.nvim/commit/7850e4ba9d8310b5587d8f649af0eb651b31ec19))

- **lua**: Render images in float windows for correct position and no tmux bleed
  ([#84](https://github.com/ansh-info/ipynb.nvim/pull/84),
  [`b6e3876`](https://github.com/ansh-info/ipynb.nvim/commit/b6e38764869c99378c98c3504101e15c982a3171))


## v1.4.1 (2026-03-30)

### Bug Fixes

- **config**: Change run_cell default from <leader>r to <leader>rr
  ([#79](https://github.com/ansh-info/ipynb.nvim/pull/79),
  [`e771267`](https://github.com/ansh-info/ipynb.nvim/commit/e77126748eaf52c398d9c6735ca194a25b77b8d8))

- **lua**: Keep off-screen images in registry for scroll retry
  ([#78](https://github.com/ansh-info/ipynb.nvim/pull/78),
  [`c3f4353`](https://github.com/ansh-info/ipynb.nvim/commit/c3f435307ecc88e5d8baabc2325f62be29d6ddda))

- **lua**: Persist cell outputs to notebook model on execution
  ([#80](https://github.com/ansh-info/ipynb.nvim/pull/80),
  [`feab789`](https://github.com/ansh-info/ipynb.nvim/commit/feab78927ded22917f8c6c81924ce0bb38ec2349))

### Documentation

- **docs**: Update <leader>r to <leader>rr in README keymaps
  ([#79](https://github.com/ansh-info/ipynb.nvim/pull/79),
  [`1672157`](https://github.com/ansh-info/ipynb.nvim/commit/1672157429aa70d646c5f8e14ba8658e1b9bc1d6))


## v1.4.0 (2026-03-30)

### Chores

- **config**: Set ignore_merge_commits = true for semantic release
  ([`cf5b1ff`](https://github.com/ansh-info/ipynb.nvim/commit/cf5b1ffe83d6ead3c3d95a8019b3d2d718151db8))

- **config**: Update root uv.lock after pyproject.toml change
  ([`a91583a`](https://github.com/ansh-info/ipynb.nvim/commit/a91583a5d7d8ef42ea749a422485ae66bf610443))

### Documentation

- **docs**: Add markdown cell commands and keymaps to README
  ([`8d2ef0f`](https://github.com/ansh-info/ipynb.nvim/commit/8d2ef0f6dc4dccd30f425acb9799b1d0d1ee94d5))

### Features

- **config**: Add add_markdown_below and add_markdown_above keymap defaults
  ([`4706755`](https://github.com/ansh-info/ipynb.nvim/commit/470675501e29f1aaa65fa99124d6357cfc23fcae))

- **lua**: Add IpynbCellAddMarkdown and IpynbCellAddMarkdownAbove commands
  ([`32738c0`](https://github.com/ansh-info/ipynb.nvim/commit/32738c0a808ddb2677c239508b7e53d8bf44ac83))

- **lua**: Add markdown cell keymaps and help overlay entries
  ([`95603d7`](https://github.com/ansh-info/ipynb.nvim/commit/95603d7b63193c5a2ecc71d0f83d312a524540fa))

- **lua**: Add optional cell_type param to add_cell_below/above
  ([`8c731ad`](https://github.com/ansh-info/ipynb.nvim/commit/8c731adc6d9a829134df8e2c05213fe44f89d8de))


## v1.3.1 (2026-03-30)

### Bug Fixes

- Wire auto_save and improve kernel crash notification
  ([#75](https://github.com/ansh-info/ipynb.nvim/pull/75),
  [`b887b8e`](https://github.com/ansh-info/ipynb.nvim/commit/b887b8e92eb3f5b0511a42d552465535fbed3472))

- **lua**: Fix stylua formatting in on_exit error messages
  ([#75](https://github.com/ansh-info/ipynb.nvim/pull/75),
  [`b887b8e`](https://github.com/ansh-info/ipynb.nvim/commit/b887b8e92eb3f5b0511a42d552465535fbed3472))

- **lua**: Fix stylua formatting in on_exit error messages
  ([`6355bd9`](https://github.com/ansh-info/ipynb.nvim/commit/6355bd9fc57354aa7ec18c502c6947590b96df18))

- **lua**: Wire auto_save and improve kernel crash handling
  ([#75](https://github.com/ansh-info/ipynb.nvim/pull/75),
  [`b887b8e`](https://github.com/ansh-info/ipynb.nvim/commit/b887b8e92eb3f5b0511a42d552465535fbed3472))

- **lua**: Wire auto_save and improve kernel crash handling
  ([`b87b3c2`](https://github.com/ansh-info/ipynb.nvim/commit/b87b3c293b4c21268aefcc5ada8075bcf3221bd9))


## v1.3.0 (2026-03-30)

### Documentation

- **docs**: Add clear output commands, keymaps, and config to README
  ([#76](https://github.com/ansh-info/ipynb.nvim/pull/76),
  [`e982b99`](https://github.com/ansh-info/ipynb.nvim/commit/e982b998ae0d2803bfb61096072403ee8caa5120))

- **docs**: Add clear output commands, keymaps, and config to README
  ([`599efe0`](https://github.com/ansh-info/ipynb.nvim/commit/599efe0c938b1c9fd79827abd41ac14da2615ec9))

### Features

- Add IpynbClearOutput and IpynbClearAllOutput commands
  ([#76](https://github.com/ansh-info/ipynb.nvim/pull/76),
  [`e982b99`](https://github.com/ansh-info/ipynb.nvim/commit/e982b998ae0d2803bfb61096072403ee8caa5120))

- **config**: Add clear_output and clear_all_output keymap defaults
  ([#76](https://github.com/ansh-info/ipynb.nvim/pull/76),
  [`e982b99`](https://github.com/ansh-info/ipynb.nvim/commit/e982b998ae0d2803bfb61096072403ee8caa5120))

- **config**: Add clear_output and clear_all_output keymap defaults
  ([`c6a34a2`](https://github.com/ansh-info/ipynb.nvim/commit/c6a34a25de9dade37b2794659ad44fe57101bac8))

- **lua**: Add clear_output and clear_all_output keymaps
  ([#76](https://github.com/ansh-info/ipynb.nvim/pull/76),
  [`e982b99`](https://github.com/ansh-info/ipynb.nvim/commit/e982b998ae0d2803bfb61096072403ee8caa5120))

- **lua**: Add clear_output and clear_all_output keymaps
  ([`8589646`](https://github.com/ansh-info/ipynb.nvim/commit/85896465f8780d06dd1fdc161d074c17d3b477f9))

- **lua**: Add IpynbClearOutput and IpynbClearAllOutput commands
  ([#76](https://github.com/ansh-info/ipynb.nvim/pull/76),
  [`e982b99`](https://github.com/ansh-info/ipynb.nvim/commit/e982b998ae0d2803bfb61096072403ee8caa5120))

- **lua**: Add IpynbClearOutput and IpynbClearAllOutput commands
  ([`52b38d4`](https://github.com/ansh-info/ipynb.nvim/commit/52b38d4c6f29d202b7515a41ff36b89d3edab3f1))


## v1.2.2 (2026-03-30)

### Bug Fixes

- Structural undo recovery - blank buffer and border sync
  ([#73](https://github.com/ansh-info/ipynb.nvim/pull/73),
  [`dd49cca`](https://github.com/ansh-info/ipynb.nvim/commit/dd49cca14332e25eb6b863e96193f821e19ef328))

- **lua**: Add structural undo recovery to cell.lua
  ([#73](https://github.com/ansh-info/ipynb.nvim/pull/73),
  [`dd49cca`](https://github.com/ansh-info/ipynb.nvim/commit/dd49cca14332e25eb6b863e96193f821e19ef328))

- **lua**: Add structural undo recovery to cell.lua
  ([`b0e21af`](https://github.com/ansh-info/ipynb.nvim/commit/b0e21af663af50982b873c746240f0c550ab2853))

- **lua**: Call sync_sources and check_structural_integrity on TextChanged
  ([#73](https://github.com/ansh-info/ipynb.nvim/pull/73),
  [`dd49cca`](https://github.com/ansh-info/ipynb.nvim/commit/dd49cca14332e25eb6b863e96193f821e19ef328))

- **lua**: Call sync_sources and check_structural_integrity on TextChanged
  ([`8e42875`](https://github.com/ansh-info/ipynb.nvim/commit/8e4287589adf9d7a1ab11f8d5bcfbe14cc0d5521))

### Documentation

- Update README and CLAUDE.md for v1.2 changes
  ([#71](https://github.com/ansh-info/ipynb.nvim/pull/71),
  [`b4fe0f7`](https://github.com/ansh-info/ipynb.nvim/commit/b4fe0f7540c9219638e447b30f35ea5612344dd9))

- **docs**: Add run_cell_and_advance keymap, command, and config entry
  ([#71](https://github.com/ansh-info/ipynb.nvim/pull/71),
  [`b4fe0f7`](https://github.com/ansh-info/ipynb.nvim/commit/b4fe0f7540c9219638e447b30f35ea5612344dd9))

- **docs**: Add run_cell_and_advance keymap, command, and config entry
  ([`ae53495`](https://github.com/ansh-info/ipynb.nvim/commit/ae534950a010c10728923630fec7644e87437081))

- **docs**: Trim CLAUDE.md - remove implementation details and phase history
  ([#72](https://github.com/ansh-info/ipynb.nvim/pull/72),
  [`ab0674b`](https://github.com/ansh-info/ipynb.nvim/commit/ab0674bb9b7e94cdf10bdb13d09c4e26907649a0))

- **docs**: Trim CLAUDE.md - remove implementation details and phase history
  ([`65b83b8`](https://github.com/ansh-info/ipynb.nvim/commit/65b83b89c0c36bb6bf5fc658d2d90c107f691be3))

- **docs**: Update CLAUDE.md for v1.2 stability changes
  ([#71](https://github.com/ansh-info/ipynb.nvim/pull/71),
  [`b4fe0f7`](https://github.com/ansh-info/ipynb.nvim/commit/b4fe0f7540c9219638e447b30f35ea5612344dd9))

- **docs**: Update CLAUDE.md for v1.2 stability changes
  ([`a95210b`](https://github.com/ansh-info/ipynb.nvim/commit/a95210b14f053e3b9515bc2261639421702162ba))


## v1.2.1 (2026-03-30)

### Bug Fixes

- Undo stability, cursor snap crash, and image tmux bleed
  ([#70](https://github.com/ansh-info/ipynb.nvim/pull/70),
  [`77218ac`](https://github.com/ansh-info/ipynb.nvim/commit/77218ac212b17c5379529d983f93b50be2f1c91a))

- **lua**: Guard snap_cursor_to_nearest and reanchor_end_marks against stale extmarks
  ([#70](https://github.com/ansh-info/ipynb.nvim/pull/70),
  [`77218ac`](https://github.com/ansh-info/ipynb.nvim/commit/77218ac212b17c5379529d983f93b50be2f1c91a))

- **lua**: Guard snap_cursor_to_nearest and reanchor_end_marks against stale extmarks
  ([`14289e9`](https://github.com/ansh-info/ipynb.nvim/commit/14289e9d07518ebfd2bc6cae1b33287bb071fd15))

- **lua**: Skip image render when end_row is below visible window area
  ([#70](https://github.com/ansh-info/ipynb.nvim/pull/70),
  [`77218ac`](https://github.com/ansh-info/ipynb.nvim/commit/77218ac212b17c5379529d983f93b50be2f1c91a))

- **lua**: Skip image render when end_row is below visible window area
  ([`b0bb686`](https://github.com/ansh-info/ipynb.nvim/commit/b0bb6867eef789e429b46775d72fc0fbe7d28c7b))


## v1.2.0 (2026-03-30)

### Bug Fixes

- Critical bugs - saved outputs, undo crash, cursor escape, run and advance
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Add CursorMoved guard to prevent typing outside cell regions
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Add CursorMoved guard to prevent typing outside cell regions
  ([`0917c88`](https://github.com/ansh-info/ipynb.nvim/commit/0917c880eb7bc79869bd1e2bf8ba71599ed9ca21))

- **lua**: Call output.restore() on render and add snap_cursor_to_nearest
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Call output.restore() on render and add snap_cursor_to_nearest
  ([`e26d46c`](https://github.com/ansh-info/ipynb.nvim/commit/e26d46ce728dd2a22a934a98ef01ee2ef2628e20))

- **lua**: Clamp end_row to buffer length before passing to image.nvim
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Clamp end_row to buffer length before passing to image.nvim
  ([`b3ae6e6`](https://github.com/ansh-info/ipynb.nvim/commit/b3ae6e64db4aaff956c125b9db9d1e760f9a4f14))

- **lua**: Restore saved cell outputs when opening a notebook
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Restore saved cell outputs when opening a notebook
  ([`f8724f5`](https://github.com/ansh-info/ipynb.nvim/commit/f8724f58c568debc4164ca1e2fcf7446eb11b727))

### Features

- **config**: Add run_cell_and_advance keymap default
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **config**: Add run_cell_and_advance keymap default
  ([`ac4112a`](https://github.com/ansh-info/ipynb.nvim/commit/ac4112ac622c3054a6ea06daad09ca1e3fa0ba82))

- **lua**: Add :IpynbRunAdvance command ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Add :IpynbRunAdvance command
  ([`5000a9a`](https://github.com/ansh-info/ipynb.nvim/commit/5000a9a4f926a1723e03dcf5cb948554ca671e9a))

- **lua**: Add run_cell_and_advance (Shift+Enter equivalent)
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Add run_cell_and_advance (Shift+Enter equivalent)
  ([`8d2c9e5`](https://github.com/ansh-info/ipynb.nvim/commit/8d2c9e59646ad899580d7e84706a694088eda345))

- **lua**: Wire <leader>rn keymap for run_cell_and_advance
  ([#69](https://github.com/ansh-info/ipynb.nvim/pull/69),
  [`dba8919`](https://github.com/ansh-info/ipynb.nvim/commit/dba89194d153a252505d7795c67b8c081c232dd8))

- **lua**: Wire <leader>rn keymap for run_cell_and_advance
  ([`a3c4c93`](https://github.com/ansh-info/ipynb.nvim/commit/a3c4c934a23857f3c993646bfe8deea55042bd89))


## v1.1.17 (2026-03-29)

### Bug Fixes

- **lua**: Fix kernel_bridge.py path after folder restructure
  ([#59](https://github.com/ansh-info/ipynb.nvim/pull/59),
  [`8ff98d1`](https://github.com/ansh-info/ipynb.nvim/commit/8ff98d1cd4199a05430c3ec5e72adc985560d205))

- **lua**: Fix kernel_bridge.py path after folder restructure
  ([`7714532`](https://github.com/ansh-info/ipynb.nvim/commit/7714532c0a2605134fcae610e1c3932d6e8f0c6c))


## v1.1.16 (2026-03-29)

### Bug Fixes

- Phase 3 - restructure lua/ipynb/ into core/, kernel/, ui/
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update lazy ipynb.image requires in kernel/output.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update lazy ipynb.image requires in kernel/output.lua
  ([`3288cfb`](https://github.com/ansh-info/ipynb.nvim/commit/3288cfbe18fd8c5c428523c190a4e944b20511c0))

- **lua**: Update lazy ipynb.markdown require in core/cell.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update lazy ipynb.markdown require in core/cell.lua
  ([`e104eaf`](https://github.com/ansh-info/ipynb.nvim/commit/e104eaf65ff9569c040619e77bd8463e78ce474f))

- **lua**: Update lazy requires in core/notebook_buf.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update lazy requires in core/notebook_buf.lua
  ([`3152bd1`](https://github.com/ansh-info/ipynb.nvim/commit/3152bd1265e6f326e86f9b84c9bbf6c83a0fe8da))

### Chores

- **config**: Apply stylua formatting to lua/ipynb/core/cell.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **config**: Apply stylua formatting to lua/ipynb/core/cell.lua
  ([`8062556`](https://github.com/ansh-info/ipynb.nvim/commit/8062556598e9f55701119cd13932b96789752c3c))

### Documentation

- **docs**: Add CONTRIBUTING.md with setup, testing, and PR guide
  ([`4aceba2`](https://github.com/ansh-info/ipynb.nvim/commit/4aceba24c102cc6384b16227f876ca3ddf84be2c))

- **docs**: Slim Contributing section to link CONTRIBUTING.md
  ([`be5bccf`](https://github.com/ansh-info/ipynb.nvim/commit/be5bccf21816c149e57b47ac2da7d07b94520924))

- **docs**: Update CLAUDE.md for folder restructure and testing
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **docs**: Update CLAUDE.md for folder restructure and testing
  ([`3ca3977`](https://github.com/ansh-info/ipynb.nvim/commit/3ca3977ed78e17abe4edb39d381f0bf13e3aca34))

- **docs**: Update README with CI badge and contributing test guide
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **docs**: Update README with CI badge and contributing test guide
  ([`87e9165`](https://github.com/ansh-info/ipynb.nvim/commit/87e91655e109d80a3152360522fa664d7522cf96))

- **lua**: Update module name comment in lua/ipynb/core/cell.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/core/cell.lua
  ([`43d83c3`](https://github.com/ansh-info/ipynb.nvim/commit/43d83c3cb9c14e130e9a350ce764ec9fbd13459b))

- **lua**: Update module name comment in lua/ipynb/core/notebook.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/core/notebook.lua
  ([`cd9861d`](https://github.com/ansh-info/ipynb.nvim/commit/cd9861d4aac67c8468ce2ebf56e9bfd17e9902e7))

- **lua**: Update module name comment in lua/ipynb/core/notebook_buf.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/core/notebook_buf.lua
  ([`885f3d3`](https://github.com/ansh-info/ipynb.nvim/commit/885f3d3306cb7b5fbb308f20fd1e70641cae1042))

- **lua**: Update module name comment in lua/ipynb/kernel/completion.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/kernel/completion.lua
  ([`f3ed6f8`](https://github.com/ansh-info/ipynb.nvim/commit/f3ed6f8a0521732f6651dc41ab1a3f1173a64279))

- **lua**: Update module name comment in lua/ipynb/kernel/output.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/kernel/output.lua
  ([`a670a75`](https://github.com/ansh-info/ipynb.nvim/commit/a670a757291b8224ed816a99ab28b2c3f14f7155))

- **lua**: Update module name comment in lua/ipynb/ui/commands.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/ui/commands.lua
  ([`88008d2`](https://github.com/ansh-info/ipynb.nvim/commit/88008d2ad761ade97407d34d68debf83d01a6581))

- **lua**: Update module name comment in lua/ipynb/ui/image.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/ui/image.lua
  ([`2399442`](https://github.com/ansh-info/ipynb.nvim/commit/23994428e5595426800fa570b73c4d0e7220583e))

- **lua**: Update module name comment in lua/ipynb/ui/inspector.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/ui/inspector.lua
  ([`dfdd978`](https://github.com/ansh-info/ipynb.nvim/commit/dfdd9789dda7176cf59befde0e2fd4f88afa08ce))

- **lua**: Update module name comment in lua/ipynb/ui/keymaps.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/ui/keymaps.lua
  ([`fbe4ed6`](https://github.com/ansh-info/ipynb.nvim/commit/fbe4ed6d34c3d005d469a8e46ae000887712c5e8))

- **lua**: Update module name comment in lua/ipynb/ui/markdown.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update module name comment in lua/ipynb/ui/markdown.lua
  ([`ad66028`](https://github.com/ansh-info/ipynb.nvim/commit/ad66028cd8cf679989ceb9e24567eef2d2b46fe4))

### Refactoring

- **lua**: Move cell.lua to core/cell.lua ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move cell.lua to core/cell.lua
  ([`039823e`](https://github.com/ansh-info/ipynb.nvim/commit/039823e614380a051dcb7401ff611bfc0e4c3fc5))

- **lua**: Move commands.lua to ui/commands.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move commands.lua to ui/commands.lua
  ([`4732608`](https://github.com/ansh-info/ipynb.nvim/commit/47326085f335008a485a4bce872543013fb3ba31))

- **lua**: Move completion.lua to kernel/completion.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move completion.lua to kernel/completion.lua
  ([`4c00f38`](https://github.com/ansh-info/ipynb.nvim/commit/4c00f38d8536b239bc8e07d529c3c30c48bed5b8))

- **lua**: Move image.lua to ui/image.lua ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move image.lua to ui/image.lua
  ([`4c8690d`](https://github.com/ansh-info/ipynb.nvim/commit/4c8690d4543432b98a019822e0529e94451d6a49))

- **lua**: Move inspector.lua to ui/inspector.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move inspector.lua to ui/inspector.lua
  ([`a9b815e`](https://github.com/ansh-info/ipynb.nvim/commit/a9b815e20aa5756a690171dc351ff5f24ec8177a))

- **lua**: Move kernel.lua to kernel/init.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move kernel.lua to kernel/init.lua
  ([`0c3cd8d`](https://github.com/ansh-info/ipynb.nvim/commit/0c3cd8d958d075048eab143c28a0763708576d54))

- **lua**: Move keymaps.lua to ui/keymaps.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move keymaps.lua to ui/keymaps.lua
  ([`e9d9a37`](https://github.com/ansh-info/ipynb.nvim/commit/e9d9a37031a777dc42407e4a24cc0506db512a2a))

- **lua**: Move markdown.lua to ui/markdown.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move markdown.lua to ui/markdown.lua
  ([`df13a5b`](https://github.com/ansh-info/ipynb.nvim/commit/df13a5b38e5962d4f9817f0568357d47ce912ba6))

- **lua**: Move notebook.lua to core/notebook.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move notebook.lua to core/notebook.lua
  ([`2d2edb8`](https://github.com/ansh-info/ipynb.nvim/commit/2d2edb8a49de7f418d1202f0fc2c7ee7c33ee8bc))

- **lua**: Move notebook_buf.lua to core/notebook_buf.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move notebook_buf.lua to core/notebook_buf.lua
  ([`5db2c54`](https://github.com/ansh-info/ipynb.nvim/commit/5db2c54c16260e7dc9b679b95df1ba150e25901e))

- **lua**: Move output.lua to kernel/output.lua
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Move output.lua to kernel/output.lua
  ([`5d49304`](https://github.com/ansh-info/ipynb.nvim/commit/5d4930459bea7e9f2600f013f4b094f6639d6f7e))

- **lua**: Update require paths in init.lua ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update require paths in init.lua
  ([`d4af9e5`](https://github.com/ansh-info/ipynb.nvim/commit/d4af9e5f1297d1a1916dbbba28f33ee60982541c))

### Testing

- **lua**: Fix hardcoded path and stale module path in output_spec
  ([`33f4090`](https://github.com/ansh-info/ipynb.nvim/commit/33f4090e3c614d0d5e1b5703a5298221abee8520))

- **lua**: Update cell_spec.lua for core/ restructure
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update cell_spec.lua for core/ restructure
  ([`d09f09c`](https://github.com/ansh-info/ipynb.nvim/commit/d09f09c1222403e3ffe8fde568bd2c0d31e006e5))

- **lua**: Update headless_test.lua for restructured paths
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update headless_test.lua for restructured paths
  ([`324b74e`](https://github.com/ansh-info/ipynb.nvim/commit/324b74eb301552fb391b3dba3de1065fbd69e9ec))

- **lua**: Update inspector_spec.lua for ui/ restructure
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update inspector_spec.lua for ui/ restructure
  ([`ebc81a6`](https://github.com/ansh-info/ipynb.nvim/commit/ebc81a64b9e992256e51739192d49381287ebb53))

- **lua**: Update notebook_spec.lua for core/ restructure
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update notebook_spec.lua for core/ restructure
  ([`a077459`](https://github.com/ansh-info/ipynb.nvim/commit/a077459845e363513c38424ffdb313055f240c2f))

- **lua**: Update output_spec.lua for kernel/ and core/ restructure
  ([#47](https://github.com/ansh-info/ipynb.nvim/pull/47),
  [`88f2392`](https://github.com/ansh-info/ipynb.nvim/commit/88f2392d509293768825c82e74aaa4a9132ff44b))

- **lua**: Update output_spec.lua for kernel/ and core/ restructure
  ([`de89c0c`](https://github.com/ansh-info/ipynb.nvim/commit/de89c0cd8fe1c48729b2b90047840024d19285f7))


## v1.1.15 (2026-03-29)

### Bug Fixes

- **lua**: Remove unused abs_e and split long lines in markdown.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **lua**: Remove unused abs_e and split long lines in markdown.lua
  ([`bfe90e5`](https://github.com/ansh-info/ipynb.nvim/commit/bfe90e53e28cbd70a4a7eaa6a00d037ba85f2490))

- **lua**: Remove unused ext variable in image.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **lua**: Remove unused ext variable in image.lua
  ([`c4176ec`](https://github.com/ansh-info/ipynb.nvim/commit/c4176ec7f13615700dee027f4b46dec491a74cf5))

- **lua**: Remove unused s/e variables in inspector.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **lua**: Remove unused s/e variables in inspector.lua
  ([`4e19a85`](https://github.com/ansh-info/ipynb.nvim/commit/4e19a85033d220ced75c5dbef20c023a053003c1))

### Chores

- Add testing tooling (luacheck, stylua, vusted, Makefile)
  ([#44](https://github.com/ansh-info/ipynb.nvim/pull/44),
  [`5b8dd11`](https://github.com/ansh-info/ipynb.nvim/commit/5b8dd1101646ab2a8f8776a8e1a3fefc9c87033d))

- **config**: Add .luacheckrc for static analysis
  ([#44](https://github.com/ansh-info/ipynb.nvim/pull/44),
  [`5b8dd11`](https://github.com/ansh-info/ipynb.nvim/commit/5b8dd1101646ab2a8f8776a8e1a3fefc9c87033d))

- **config**: Add .luacheckrc for static analysis
  ([`3d77d47`](https://github.com/ansh-info/ipynb.nvim/commit/3d77d476e6c963cd3fc36ea7172f0c4f2fcd0986))

- **config**: Add .stylua.toml for Lua formatting
  ([#44](https://github.com/ansh-info/ipynb.nvim/pull/44),
  [`5b8dd11`](https://github.com/ansh-info/ipynb.nvim/commit/5b8dd1101646ab2a8f8776a8e1a3fefc9c87033d))

- **config**: Add .stylua.toml for Lua formatting
  ([`bb03704`](https://github.com/ansh-info/ipynb.nvim/commit/bb0370489cf5cb8201b1f345c5f384204c65abf1))

- **config**: Add Makefile with test/lint/format/ci targets
  ([#44](https://github.com/ansh-info/ipynb.nvim/pull/44),
  [`5b8dd11`](https://github.com/ansh-info/ipynb.nvim/commit/5b8dd1101646ab2a8f8776a8e1a3fefc9c87033d))

- **config**: Add Makefile with test/lint/format/ci targets
  ([`fd3bfe4`](https://github.com/ansh-info/ipynb.nvim/commit/fd3bfe457603d0855612bde48d363c169f7a95bd))

- **config**: Apply stylua formatting to lua/ipynb/cell.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/cell.lua
  ([`c8e49f4`](https://github.com/ansh-info/ipynb.nvim/commit/c8e49f4ce63db57a615d279fcf01b491dca76dfe))

- **config**: Apply stylua formatting to lua/ipynb/commands.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/commands.lua
  ([`c1ef08a`](https://github.com/ansh-info/ipynb.nvim/commit/c1ef08af9d1e6210705776a801f706a7600f9b4d))

- **config**: Apply stylua formatting to lua/ipynb/completion.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/completion.lua
  ([`e686322`](https://github.com/ansh-info/ipynb.nvim/commit/e6863226022f15b000ad50d4edf8a22d8e019ee5))

- **config**: Apply stylua formatting to lua/ipynb/config.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/config.lua
  ([`006f934`](https://github.com/ansh-info/ipynb.nvim/commit/006f93493bed4727d7a08f392d624c4b96534b40))

- **config**: Apply stylua formatting to lua/ipynb/image.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/image.lua
  ([`ccdf5d9`](https://github.com/ansh-info/ipynb.nvim/commit/ccdf5d96bb569899dc0616267102d68229429fc6))

- **config**: Apply stylua formatting to lua/ipynb/init.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/init.lua
  ([`da15e28`](https://github.com/ansh-info/ipynb.nvim/commit/da15e2823e5ce4a06f30055ed558dee3df581f61))

- **config**: Apply stylua formatting to lua/ipynb/inspector.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/inspector.lua
  ([`8d97c94`](https://github.com/ansh-info/ipynb.nvim/commit/8d97c948beea5b4e46e6a696ab9b045b90339a17))

- **config**: Apply stylua formatting to lua/ipynb/kernel.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/kernel.lua
  ([`a5fe34c`](https://github.com/ansh-info/ipynb.nvim/commit/a5fe34c84a1754cd0572a69a73759cf7b64a7413))

- **config**: Apply stylua formatting to lua/ipynb/keymaps.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/keymaps.lua
  ([`bb7ec30`](https://github.com/ansh-info/ipynb.nvim/commit/bb7ec30287fd5d78e7605416720bdb3ba168ec99))

- **config**: Apply stylua formatting to lua/ipynb/markdown.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/markdown.lua
  ([`78af481`](https://github.com/ansh-info/ipynb.nvim/commit/78af4816e19ed96d3feeefb2ca2de5a10772c622))

- **config**: Apply stylua formatting to lua/ipynb/notebook.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/notebook.lua
  ([`eef10f3`](https://github.com/ansh-info/ipynb.nvim/commit/eef10f332cca69b3cf02534f4a99a741e8b9299b))

- **config**: Apply stylua formatting to lua/ipynb/notebook_buf.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/notebook_buf.lua
  ([`5af9f49`](https://github.com/ansh-info/ipynb.nvim/commit/5af9f4909f3c0311aa8b4d99ae24a93bf60fe26f))

- **config**: Apply stylua formatting to lua/ipynb/output.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/output.lua
  ([`de82d33`](https://github.com/ansh-info/ipynb.nvim/commit/de82d33e68ee40df37c144094af626af2ab62d07))

- **config**: Apply stylua formatting to lua/ipynb/utils.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to lua/ipynb/utils.lua
  ([`3399d33`](https://github.com/ansh-info/ipynb.nvim/commit/3399d336cca0705e21369235f6ad0e2e41688de7))

- **config**: Apply stylua formatting to test/cell_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/cell_spec.lua
  ([`93b8910`](https://github.com/ansh-info/ipynb.nvim/commit/93b8910a366cedc7f255ff8f647760c02b0fdea6))

- **config**: Apply stylua formatting to test/headless_test.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/headless_test.lua
  ([`6cb2019`](https://github.com/ansh-info/ipynb.nvim/commit/6cb2019df529ed6b3b4abb95fdccd0c0f6c355e4))

- **config**: Apply stylua formatting to test/inspector_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/inspector_spec.lua
  ([`338b730`](https://github.com/ansh-info/ipynb.nvim/commit/338b7304ecc4c6ec789a16a6856026f699ecec7a))

- **config**: Apply stylua formatting to test/notebook_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/notebook_spec.lua
  ([`786a6ed`](https://github.com/ansh-info/ipynb.nvim/commit/786a6ed72bbb8747e436ec753ef6aa8c9e246481))

- **config**: Apply stylua formatting to test/output_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/output_spec.lua
  ([`c607ab8`](https://github.com/ansh-info/ipynb.nvim/commit/c607ab870b2cb87a339908a2a84a00f92826fc8f))

- **config**: Apply stylua formatting to test/utils_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **config**: Apply stylua formatting to test/utils_spec.lua
  ([`eb0d952`](https://github.com/ansh-info/ipynb.nvim/commit/eb0d952f6d4cf29943dbc36143d0c8ea868796b4))

### Continuous Integration

- Add GitHub Actions CI workflow (test, lint, format)
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- Add GitHub Actions workflow for test, lint, and format-check
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- Add GitHub Actions workflow for test, lint, and format-check
  ([`4a5c964`](https://github.com/ansh-info/ipynb.nvim/commit/4a5c964a9b026319ad19575f85dc8f5fc7049804))

### Testing

- Phase 2 - busted spec suite for all core modules
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **config**: Add minimal_init.lua for vusted test runner
  ([#44](https://github.com/ansh-info/ipynb.nvim/pull/44),
  [`5b8dd11`](https://github.com/ansh-info/ipynb.nvim/commit/5b8dd1101646ab2a8f8776a8e1a3fefc9c87033d))

- **config**: Add minimal_init.lua for vusted test runner
  ([`814d117`](https://github.com/ansh-info/ipynb.nvim/commit/814d117f6a0c78c939fa5052bf1460fac95eb63b))

- **lua**: Add busted spec for ipynb.cell module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.cell module
  ([`2fca25c`](https://github.com/ansh-info/ipynb.nvim/commit/2fca25c951aa2807323f53e5eac160449254d927))

- **lua**: Add busted spec for ipynb.config module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.config module
  ([`e61f490`](https://github.com/ansh-info/ipynb.nvim/commit/e61f4903ca0f59cd28ca79e450183b0d5a917522))

- **lua**: Add busted spec for ipynb.inspector module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.inspector module
  ([`d25bd4d`](https://github.com/ansh-info/ipynb.nvim/commit/d25bd4daf356edda8ba5ad4e465c5dcd7d9d3b99))

- **lua**: Add busted spec for ipynb.notebook module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.notebook module
  ([`7680401`](https://github.com/ansh-info/ipynb.nvim/commit/76804015769a7c742f7e4c092ec66bb1280e7c7f))

- **lua**: Add busted spec for ipynb.output module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.output module
  ([`866d1da`](https://github.com/ansh-info/ipynb.nvim/commit/866d1daa81d47c615cf8c1a1777556bcd075b408))

- **lua**: Add busted spec for ipynb.utils module
  ([#45](https://github.com/ansh-info/ipynb.nvim/pull/45),
  [`2bfd45f`](https://github.com/ansh-info/ipynb.nvim/commit/2bfd45fd9ebcc4fb32c5995cca468b8dcffeb727))

- **lua**: Add busted spec for ipynb.utils module
  ([`6994d98`](https://github.com/ansh-info/ipynb.nvim/commit/6994d98189aaa4c404fa7573663b37cebae4aaec))

- **lua**: Fix luacheck and stylua issues in inspector_spec.lua
  ([#46](https://github.com/ansh-info/ipynb.nvim/pull/46),
  [`ead9a72`](https://github.com/ansh-info/ipynb.nvim/commit/ead9a72d003ef9c06ef42bcda50605cf82368675))

- **lua**: Fix luacheck and stylua issues in inspector_spec.lua
  ([`26544a1`](https://github.com/ansh-info/ipynb.nvim/commit/26544a117d60a2b77c4daaaae600d64f46221f61))


## v1.1.14 (2026-03-28)

### Bug Fixes

- **lua**: Use pattern= not match= in nvim_exec_autocmds for FileType
  ([#42](https://github.com/ansh-info/ipynb.nvim/pull/42),
  [`be5a706`](https://github.com/ansh-info/ipynb.nvim/commit/be5a706817d9a8787e613cf3821fd69c36748186))

- **lua**: Use pattern= not match= in nvim_exec_autocmds for FileType
  ([`7c2b65b`](https://github.com/ansh-info/ipynb.nvim/commit/7c2b65b8f79bffe402141aa5a6c6f5497c49d6e3))


## v1.1.13 (2026-03-28)

### Bug Fixes

- **lua**: Guard against re-entrant image renders in output._render
  ([#41](https://github.com/ansh-info/ipynb.nvim/pull/41),
  [`22853ad`](https://github.com/ansh-info/ipynb.nvim/commit/22853ad2647fc2ec265cf0e769b5045d0d203a5f))

- **lua**: Guard against re-entrant image renders in output._render
  ([`02f0ad6`](https://github.com/ansh-info/ipynb.nvim/commit/02f0ad6af9554ddeb1b47405e1b0d86caffb3dd6))


## v1.1.12 (2026-03-28)

### Bug Fixes

- **lua**: Attach LSP clients when opening a notebook buffer
  ([#40](https://github.com/ansh-info/ipynb.nvim/pull/40),
  [`3a98311`](https://github.com/ansh-info/ipynb.nvim/commit/3a98311e344f9b55ea1a9e14ac401edb48958244))

- **lua**: Attach LSP clients when opening a notebook buffer
  ([`9d129ef`](https://github.com/ansh-info/ipynb.nvim/commit/9d129ef82fd11883ddfcbf1d3c93087d160df3f9))


## v1.1.11 (2026-03-28)

### Bug Fixes

- Re-anchor cell borders after typing or pasting
  ([#38](https://github.com/ansh-info/ipynb.nvim/pull/38),
  [`d2fb4ae`](https://github.com/ansh-info/ipynb.nvim/commit/d2fb4ae0ff7caabc274207037d103390752d427c))

- **lua**: Add reanchor_end_marks to fix cell border after o/paste
  ([#38](https://github.com/ansh-info/ipynb.nvim/pull/38),
  [`d2fb4ae`](https://github.com/ansh-info/ipynb.nvim/commit/d2fb4ae0ff7caabc274207037d103390752d427c))

- **lua**: Add reanchor_end_marks to fix cell border after o/paste
  ([`c984b21`](https://github.com/ansh-info/ipynb.nvim/commit/c984b21dfbc84f7c8da883fea20bfd388eb4a2f9))

- **lua**: Call reanchor_end_marks on InsertLeave and TextChanged
  ([#38](https://github.com/ansh-info/ipynb.nvim/pull/38),
  [`d2fb4ae`](https://github.com/ansh-info/ipynb.nvim/commit/d2fb4ae0ff7caabc274207037d103390752d427c))

- **lua**: Call reanchor_end_marks on InsertLeave and TextChanged
  ([`74f58f7`](https://github.com/ansh-info/ipynb.nvim/commit/74f58f7ed326502e3d5fa935cec006edfdd490c9))

### Documentation

- **docs**: Remove Testing locally section from CLAUDE.md
  ([#39](https://github.com/ansh-info/ipynb.nvim/pull/39),
  [`cee4b4f`](https://github.com/ansh-info/ipynb.nvim/commit/cee4b4f44cf89297e91846666eb4eed0fdcf899d))

- **docs**: Remove Testing locally section from CLAUDE.md
  ([`f19cf3d`](https://github.com/ansh-info/ipynb.nvim/commit/f19cf3d27baa883bc3713d37ae49a29052a32a02))


## v1.1.10 (2026-03-28)

### Bug Fixes

- Rerender images on scroll to fix flicker and off-screen rendering
  ([#37](https://github.com/ansh-info/ipynb.nvim/pull/37),
  [`c491706`](https://github.com/ansh-info/ipynb.nvim/commit/c491706737dcd765571409773bd32532651b9f7c))

- **lua**: Register image in registry before render for scroll retry
  ([#37](https://github.com/ansh-info/ipynb.nvim/pull/37),
  [`c491706`](https://github.com/ansh-info/ipynb.nvim/commit/c491706737dcd765571409773bd32532651b9f7c))

- **lua**: Register image in registry before render for scroll retry
  ([`089add1`](https://github.com/ansh-info/ipynb.nvim/commit/089add1369e3660bbcfa7711af836f47ac6ad9dd))

- **lua**: Rerender images on WinScrolled with 80ms debounce
  ([#37](https://github.com/ansh-info/ipynb.nvim/pull/37),
  [`c491706`](https://github.com/ansh-info/ipynb.nvim/commit/c491706737dcd765571409773bd32532651b9f7c))

- **lua**: Rerender images on WinScrolled with 80ms debounce
  ([`dba38e2`](https://github.com/ansh-info/ipynb.nvim/commit/dba38e2e612eeb18b287a9328a147d6524366197))


## v1.1.9 (2026-03-28)

### Bug Fixes

- **lua**: Filter IPython builtins from variable inspector
  ([#32](https://github.com/ansh-info/ipynb.nvim/pull/32),
  [`36f5699`](https://github.com/ansh-info/ipynb.nvim/commit/36f56999aba34ee1b782159c28db5de490112a7e))

- **lua**: Filter IPython builtins from variable inspector
  ([`1aa365e`](https://github.com/ansh-info/ipynb.nvim/commit/1aa365e28040603e4e9e2ded6f71cf85a5b2931a))


## v1.1.8 (2026-03-28)

### Bug Fixes

- Image always rendered at top of buffer due to wrong geometry API
  ([#31](https://github.com/ansh-info/ipynb.nvim/pull/31),
  [`3e0d4b5`](https://github.com/ansh-info/ipynb.nvim/commit/3e0d4b5060f6e0f25b2bfa33f97746c068f9296c))

- **lua**: Drop text_line_offset from image render queue
  ([#31](https://github.com/ansh-info/ipynb.nvim/pull/31),
  [`3e0d4b5`](https://github.com/ansh-info/ipynb.nvim/commit/3e0d4b5060f6e0f25b2bfa33f97746c068f9296c))

- **lua**: Drop text_line_offset from image render queue
  ([`e762b4c`](https://github.com/ansh-info/ipynb.nvim/commit/e762b4ca8809c37517a8851ce0a4eb84b3b2b062))

- **lua**: Pass geometry as flat options to image.nvim from_file
  ([#31](https://github.com/ansh-info/ipynb.nvim/pull/31),
  [`3e0d4b5`](https://github.com/ansh-info/ipynb.nvim/commit/3e0d4b5060f6e0f25b2bfa33f97746c068f9296c))

- **lua**: Pass geometry as flat options to image.nvim from_file
  ([`162f789`](https://github.com/ansh-info/ipynb.nvim/commit/162f78900c839b0844a54e2b2ce1b9019f81c450))


## v1.1.7 (2026-03-28)

### Bug Fixes

- Simplify image rendering setup to use magick_cli processor
  ([#30](https://github.com/ansh-info/ipynb.nvim/pull/30),
  [`a2ceec3`](https://github.com/ansh-info/ipynb.nvim/commit/a2ceec33afd7102fad5d02d1487e980b3dc9f820))

### Documentation

- **docs**: Simplify image rendering setup to use magick_cli processor
  ([`99350b4`](https://github.com/ansh-info/ipynb.nvim/commit/99350b4cd5ce462af55492e08ed4475fdbfe2c05))


## v1.1.6 (2026-03-28)

### Bug Fixes

- **lua**: Use file-based base64 decode, support macOS -D flag
  ([#28](https://github.com/ansh-info/ipynb.nvim/pull/28),
  [`106e516`](https://github.com/ansh-info/ipynb.nvim/commit/106e516022b5efad1c6ede3edc0888e872f105e5))

- **lua**: Use file-based base64 decode, support macOS -D flag
  ([`d000416`](https://github.com/ansh-info/ipynb.nvim/commit/d000416baf7a9c0d887d8194affe03df338fc600))

### Documentation

- **docs**: Add tmux allow-passthrough requirement for image rendering
  ([#27](https://github.com/ansh-info/ipynb.nvim/pull/27),
  [`9dcd508`](https://github.com/ansh-info/ipynb.nvim/commit/9dcd508c1823cfca8b37ad8e744a60c77116d72b))

- **docs**: Add tmux allow-passthrough requirement for image rendering
  ([`7b735b7`](https://github.com/ansh-info/ipynb.nvim/commit/7b735b79dca940ed626499e1bd024c1abf1933ce))

- **docs**: Fix image.nvim luarocks install for macOS ImageMagick 7
  ([#25](https://github.com/ansh-info/ipynb.nvim/pull/25),
  [`6f1a2cf`](https://github.com/ansh-info/ipynb.nvim/commit/6f1a2cfec3549e7a98b6352da2917b557c8f979c))

- **docs**: Fix image.nvim luarocks install for macOS ImageMagick 7
  ([`85e6571`](https://github.com/ansh-info/ipynb.nvim/commit/85e6571a449ce18ae9d0aa9001364fa1f38829fc))

- **docs**: Replace lua@5.1 with luajit for macOS magick install
  ([#26](https://github.com/ansh-info/ipynb.nvim/pull/26),
  [`5b9bb5c`](https://github.com/ansh-info/ipynb.nvim/commit/5b9bb5c7e3de3838c8411ce12577230fc37a6e58))

- **docs**: Replace lua@5.1 with luajit for macOS magick install
  ([`1e3c194`](https://github.com/ansh-info/ipynb.nvim/commit/1e3c19425c6e810194c9724c5b8848d59e899286))


## v1.1.5 (2026-03-28)

### Bug Fixes

- Inspector extmark crash and image.nvim setup docs
  ([#24](https://github.com/ansh-info/ipynb.nvim/pull/24),
  [`b78d386`](https://github.com/ansh-info/ipynb.nvim/commit/b78d3862a8c4435c154706c15ce6f062e846c22d))

- **lua**: Clamp extmark end_col to actual line length in inspector
  ([#24](https://github.com/ansh-info/ipynb.nvim/pull/24),
  [`b78d386`](https://github.com/ansh-info/ipynb.nvim/commit/b78d3862a8c4435c154706c15ce6f062e846c22d))

- **lua**: Clamp extmark end_col to actual line length in inspector
  ([`392c54b`](https://github.com/ansh-info/ipynb.nvim/commit/392c54bdbc44a264e5ef1a3a434d53aa19772cfd))

### Documentation

- **docs**: Document image.nvim setup with luarocks and magick
  ([#24](https://github.com/ansh-info/ipynb.nvim/pull/24),
  [`b78d386`](https://github.com/ansh-info/ipynb.nvim/commit/b78d3862a8c4435c154706c15ce6f062e846c22d))

- **docs**: Document image.nvim setup with luarocks and magick
  ([`cec5cb0`](https://github.com/ansh-info/ipynb.nvim/commit/cec5cb0e88aa14eb382e6f709c56e620e791e880))

### Testing

- **docs**: Remove matplotlib.use('Agg') from test notebook
  ([#23](https://github.com/ansh-info/ipynb.nvim/pull/23),
  [`fbba075`](https://github.com/ansh-info/ipynb.nvim/commit/fbba075d5b31e9fe5de387b8751ab00a9bf8b68b))

- **docs**: Remove matplotlib.use('Agg') from test notebook
  ([`dc488d4`](https://github.com/ansh-info/ipynb.nvim/commit/dc488d47f3927e8b8a7cc2530d21ca59bf895019))


## v1.1.4 (2026-03-28)

### Bug Fixes

- Inspector format crash and matplotlib race condition
  ([#20](https://github.com/ansh-info/ipynb.nvim/pull/20),
  [`c2f1dae`](https://github.com/ansh-info/ipynb.nvim/commit/c2f1dae721d5c29369c144325a31bfaae2ff3ba2))

- **lua**: Replace %-*s dynamic-width format spec with literal widths
  ([#20](https://github.com/ansh-info/ipynb.nvim/pull/20),
  [`c2f1dae`](https://github.com/ansh-info/ipynb.nvim/commit/c2f1dae721d5c29369c144325a31bfaae2ff3ba2))

- **lua**: Replace %-*s dynamic-width format spec with literal widths
  ([`3d2b233`](https://github.com/ansh-info/ipynb.nvim/commit/3d2b233786e077c5428807cdb83e693eef43634d))

- **python**: Wait for %matplotlib inline before notifying Lua kernel is ready
  ([#20](https://github.com/ansh-info/ipynb.nvim/pull/20),
  [`c2f1dae`](https://github.com/ansh-info/ipynb.nvim/commit/c2f1dae721d5c29369c144325a31bfaae2ff3ba2))

- **python**: Wait for %matplotlib inline before notifying Lua kernel is ready
  ([`876357f`](https://github.com/ansh-info/ipynb.nvim/commit/876357f6d73402bc844e14824c1f94b08a4cfa05))

### Testing

- **lua**: Add headless Neovim test suite ([#20](https://github.com/ansh-info/ipynb.nvim/pull/20),
  [`c2f1dae`](https://github.com/ansh-info/ipynb.nvim/commit/c2f1dae721d5c29369c144325a31bfaae2ff3ba2))

- **lua**: Add headless Neovim test suite
  ([`84c1453`](https://github.com/ansh-info/ipynb.nvim/commit/84c1453a2226783224b8305e30d3cfea5cb1f3f5))


## v1.1.3 (2026-03-28)

### Bug Fixes

- Variable inspector and matplotlib inline backend
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **lua**: Add execute_snippet API and route snippet pending in dispatch
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **lua**: Add execute_snippet API and route snippet pending in dispatch
  ([`e0027a0`](https://github.com/ansh-info/ipynb.nvim/commit/e0027a0d67b1563ec9e506def0a7d3c370a07305))

- **lua**: Rewrite inspector to use kernel.execute_snippet
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **lua**: Rewrite inspector to use kernel.execute_snippet
  ([`8b64d54`](https://github.com/ansh-info/ipynb.nvim/commit/8b64d54ae72803aedbbbe05a56da9eb3c6ba5d28))

- **lua**: Skip execution when cursor is inside a markdown cell
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **lua**: Skip execution when cursor is inside a markdown cell
  ([`e1ec012`](https://github.com/ansh-info/ipynb.nvim/commit/e1ec012653d46c796933337cae3339f5fac49ded))

- **python**: Auto-configure matplotlib inline backend on kernel start
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **python**: Auto-configure matplotlib inline backend on kernel start
  ([`9ba714c`](https://github.com/ansh-info/ipynb.nvim/commit/9ba714cc0c6f5e5c74a6ada7f8c2b535ffbf76ba))

- **python**: Suppress IOPub output from silent kernel setup commands
  ([#19](https://github.com/ansh-info/ipynb.nvim/pull/19),
  [`1eeafaa`](https://github.com/ansh-info/ipynb.nvim/commit/1eeafaae4fa2e1809694bbbd0ae47f4514f352eb))

- **python**: Suppress IOPub output from silent kernel setup commands
  ([`f2dce0d`](https://github.com/ansh-info/ipynb.nvim/commit/f2dce0dbc1aaafc107326aa39dfdfc482335165f))


## v1.1.2 (2026-03-28)

### Bug Fixes

- Cursor at bottom on open, venv ipykernel check
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **lua**: Reset cursor to line 1 after notebook opens
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **lua**: Reset cursor to line 1 after notebook opens
  ([`583229a`](https://github.com/ansh-info/ipynb.nvim/commit/583229a47366ee3c1d659774fb3c409170b68750))

- **python**: Use kernel_spec.argv[0] mutation to set venv Python
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **python**: Use kernel_spec.argv[0] mutation to set venv Python
  ([`c44a0f7`](https://github.com/ansh-info/ipynb.nvim/commit/c44a0f735a7443954d5a3e09534670037f4c9a90))

- **python**: Verify ipykernel in venv before using it as kernel Python
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **python**: Verify ipykernel in venv before using it as kernel Python
  ([`458a50a`](https://github.com/ansh-info/ipynb.nvim/commit/458a50ab2a34a8ae794e809ef166019568d6e633))

### Documentation

- **docs**: Add pre-commit testing checklist and review process
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **docs**: Add pre-commit testing checklist and review process
  ([`8d436f2`](https://github.com/ansh-info/ipynb.nvim/commit/8d436f23a2ad8d3edae07287f02eb44eb72c791a))

- **docs**: Document project venv setup for numpy/matplotlib in README
  ([#18](https://github.com/ansh-info/ipynb.nvim/pull/18),
  [`7b5ee7d`](https://github.com/ansh-info/ipynb.nvim/commit/7b5ee7d873c2a664b7ac589fae3ff15109208575))

- **docs**: Document project venv setup for numpy/matplotlib in README
  ([`b11aead`](https://github.com/ansh-info/ipynb.nvim/commit/b11aead0eeaa4c0c0ae9476ce9a9ded144fb2137))


## v1.1.1 (2026-03-28)

### Bug Fixes

- Complete/inspect crash, venv auto-detection, formatter corruption
  ([#17](https://github.com/ansh-info/ipynb.nvim/pull/17),
  [`4bcdf23`](https://github.com/ansh-info/ipynb.nvim/commit/4bcdf238fe24f3e4b606646c342024bb347a9e51))

- **lua**: Disable formatters on ipynb buffers to prevent code corruption
  ([#17](https://github.com/ansh-info/ipynb.nvim/pull/17),
  [`4bcdf23`](https://github.com/ansh-info/ipynb.nvim/commit/4bcdf238fe24f3e4b606646c342024bb347a9e51))

- **lua**: Disable formatters on ipynb buffers to prevent code corruption
  ([`db9de4b`](https://github.com/ansh-info/ipynb.nvim/commit/db9de4bf7a9678ee0442e8a99b3e2d670008986f))

- **python**: Fix complete/inspect and auto-detect venv Python for kernel
  ([#17](https://github.com/ansh-info/ipynb.nvim/pull/17),
  [`4bcdf23`](https://github.com/ansh-info/ipynb.nvim/commit/4bcdf238fe24f3e4b606646c342024bb347a9e51))

- **python**: Fix complete/inspect and auto-detect venv Python for kernel
  ([`21cab35`](https://github.com/ansh-info/ipynb.nvim/commit/21cab35275a6098e1f8cc29b47890f889fecd908))


## v1.1.0 (2026-03-28)

### Bug Fixes

- Restore version bumps and upgrade to Node.js 24 actions
  ([#16](https://github.com/ansh-info/ipynb.nvim/pull/16),
  [`3d56aaa`](https://github.com/ansh-info/ipynb.nvim/commit/3d56aaae8eb3b5231ca60bc9aee894c42ec24e31))

- **ci**: Upgrade actions/checkout to v6 and setup-python to v6 for Node.js 24
  ([#16](https://github.com/ansh-info/ipynb.nvim/pull/16),
  [`3d56aaa`](https://github.com/ansh-info/ipynb.nvim/commit/3d56aaae8eb3b5231ca60bc9aee894c42ec24e31))

- **ci**: Upgrade actions/checkout to v6 and setup-python to v6 for Node.js 24
  ([`22a8b12`](https://github.com/ansh-info/ipynb.nvim/commit/22a8b12c8a8e11f9562e2ca3908e0b3cf8dd11db))

- **config**: Set ignore_merge_commits = false so PR titles drive version bumps
  ([#16](https://github.com/ansh-info/ipynb.nvim/pull/16),
  [`3d56aaa`](https://github.com/ansh-info/ipynb.nvim/commit/3d56aaae8eb3b5231ca60bc9aee894c42ec24e31))

- **config**: Set ignore_merge_commits = false so PR titles drive version bumps
  ([`a0d0b5f`](https://github.com/ansh-info/ipynb.nvim/commit/a0d0b5f6214e02115e6fdb3ab87bf4ca5758d430))

### Chores

- **config**: Regenerate python/uv.lock after ipynb-nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Regenerate python/uv.lock after ipynb-nvim rename
  ([`e51e9ed`](https://github.com/ansh-info/ipynb.nvim/commit/e51e9ed85ab052de5ac5951d604f93003c01ae70))

- **config**: Regenerate root uv.lock after ipynb-nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Regenerate root uv.lock after ipynb-nvim rename
  ([`adab316`](https://github.com/ansh-info/ipynb.nvim/commit/adab316c9574405fa47f74e77b07297706ac96d8))

- **config**: Update bug report template commands for ipynb.nvim
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Update bug report template commands for ipynb.nvim
  ([`7c5da81`](https://github.com/ansh-info/ipynb.nvim/commit/7c5da8185b7ac9aaa6a148bc0826aa93bab51c24))

- **config**: Update issue template config URL for ipynb.nvim
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Update issue template config URL for ipynb.nvim
  ([`bc9a386`](https://github.com/ansh-info/ipynb.nvim/commit/bc9a38653d1f223ea213b27e44b0f16a43c5bfaa))

- **config**: Update python/uv.lock for ipynb-nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Update python/uv.lock for ipynb-nvim rename
  ([`231c885`](https://github.com/ansh-info/ipynb.nvim/commit/231c88504e1515e7100e8d3efb077da39b13cc36))

- **config**: Update root uv.lock for ipynb-nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Update root uv.lock for ipynb-nvim rename
  ([`2d1799c`](https://github.com/ansh-info/ipynb.nvim/commit/2d1799ca49a5ae3a64dd2d9bccb1ba561b10ad12))

### Documentation

- **docs**: Document both uv projects and correct sync/lock workflow
  ([#16](https://github.com/ansh-info/ipynb.nvim/pull/16),
  [`3d56aaa`](https://github.com/ansh-info/ipynb.nvim/commit/3d56aaae8eb3b5231ca60bc9aee894c42ec24e31))

- **docs**: Document both uv projects and correct sync/lock workflow
  ([`fe94528`](https://github.com/ansh-info/ipynb.nvim/commit/fe94528fb54917cf86cb9459659857c60c049b42))

- **docs**: Update CHANGELOG repo URLs for ipynb.nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **docs**: Update CHANGELOG repo URLs for ipynb.nvim rename
  ([`49f30d1`](https://github.com/ansh-info/ipynb.nvim/commit/49f30d1a42defc475740aa9ae65521acd5ca7b39))

- **docs**: Update CLAUDE.md for ipynb.nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **docs**: Update CLAUDE.md for ipynb.nvim rename
  ([`71edec5`](https://github.com/ansh-info/ipynb.nvim/commit/71edec542bf9c288d28669a171c267d11b80fef3))

- **docs**: Update README for ipynb.nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **docs**: Update README for ipynb.nvim rename
  ([`59bfdc0`](https://github.com/ansh-info/ipynb.nvim/commit/59bfdc00452a0b1cb9778b7322cbcedb7c21e678))

### Features

- Rename plugin to ipynb.nvim ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

### Refactoring

- **config**: Rename python package to ipynb-nvim
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Rename python package to ipynb-nvim
  ([`02114c3`](https://github.com/ansh-info/ipynb.nvim/commit/02114c3baf2afb0b0edd3609970700fc640aa7f2))

- **config**: Rename root package to ipynb-nvim
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **config**: Rename root package to ipynb-nvim
  ([`905f752`](https://github.com/ansh-info/ipynb.nvim/commit/905f752221721401efdb872072f693c8f37035e4))

- **lua**: Rename lua/jupytervim/ to lua/ipynb/
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **lua**: Rename lua/jupytervim/ to lua/ipynb/
  ([`8d4546a`](https://github.com/ansh-info/ipynb.nvim/commit/8d4546a352a9a86a17a153d28cd3f38e8ecd502e))

- **plugin**: Rename plugin/jupytervim.lua to plugin/ipynb.lua
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **plugin**: Rename plugin/jupytervim.lua to plugin/ipynb.lua
  ([`d3c9c49`](https://github.com/ansh-info/ipynb.nvim/commit/d3c9c49753836efc950d390dc40d190b30298ed8))

- **python**: Update command references to IpynbKernelStart
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- **python**: Update command references to IpynbKernelStart
  ([`20e9f3a`](https://github.com/ansh-info/ipynb.nvim/commit/20e9f3a36224310d71152c9019be02145999d484))

### Testing

- Update test notebook strings for ipynb.nvim rename
  ([#15](https://github.com/ansh-info/ipynb.nvim/pull/15),
  [`6c868e4`](https://github.com/ansh-info/ipynb.nvim/commit/6c868e484d9bde213a60988812b61fa7f98b6ebf))

- Update test notebook strings for ipynb.nvim rename
  ([`a518243`](https://github.com/ansh-info/ipynb.nvim/commit/a5182432ec9ecfe3ba81aa6fce2e4f755462c8f8))


## v1.0.3 (2026-03-28)

### Bug Fixes

- **docs**: Add return wrapper to lazy.nvim install snippets in README
  ([`f33291f`](https://github.com/ansh-info/ipynb.nvim/commit/f33291f77e66f4bebe94a1cb1b98b3d53922f9d7))

### Chores

- **config**: Add bug report issue template
  ([`a05bbac`](https://github.com/ansh-info/ipynb.nvim/commit/a05bbaced8328ad72c08cfe0cfe5991a066cb030))

- **config**: Add feature request issue template
  ([`e826d8d`](https://github.com/ansh-info/ipynb.nvim/commit/e826d8daeb034633463d73c8fd18b42720f13259))

- **config**: Add other/question issue template
  ([`bce7b45`](https://github.com/ansh-info/ipynb.nvim/commit/bce7b45299ddb978111b3fc81a281f1023b0b811))

- **config**: Disable blank issues, add discussions link
  ([`6d744fb`](https://github.com/ansh-info/ipynb.nvim/commit/6d744fb0e90621fb1b7079b3005a6084fd23acd5))

### Documentation

- **docs**: Add branch naming and PR description guide to CLAUDE.md
  ([`6f31abb`](https://github.com/ansh-info/ipynb.nvim/commit/6f31abb9f3b8ca8fef1d65815b61bece4d2c5edf))


## v1.0.2 (2026-03-28)

### Bug Fixes

- **ci**: Upgrade actions to Node.js 24 compatible versions
  ([`0d8dea3`](https://github.com/ansh-info/ipynb.nvim/commit/0d8dea3e1d12dad6c306e4a62cdf0413543291f0))


## v1.0.1 (2026-03-28)

### Bug Fixes

- **docs**: Replace em dashes with hyphens in README
  ([`225d520`](https://github.com/ansh-info/ipynb.nvim/commit/225d520b71eebabe96b499b635195daa84473d13))

- **docs**: Replace em dashes with hyphens, add no-em-dash rule to CLAUDE.md
  ([`9652a23`](https://github.com/ansh-info/ipynb.nvim/commit/9652a23170f7b571b284f46ca2a946d53eae1251))


## v1.0.0 (2026-03-28)

- Initial Release
