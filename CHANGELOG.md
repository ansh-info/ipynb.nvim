# CHANGELOG

<!-- version list -->

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
