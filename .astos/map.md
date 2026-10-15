# ASTOS MAP — porte
> Gerado por `astos` em 2026-10-15 03:34 UTC. 28 arquivos · 35 dependências · 42 chamadas inter-arquivo · langs: c, dart, java, kotlin.
> Se desatualizado: `astos -f` (atualiza sem abrir o navegador). Detalhe: `.astos/graph.json`. Visual humano: `.astos/index.html` + `.astos/city.html` (palácio).
> Queries baratas (use em vez de grep): `astos q --symbol X` · `astos q --cap camera` · `astos trace --from A --to B` · `astos impact --file F` · `astos caps` · `astos hubs` · `astos risks` · `astos slice <pasta>` · `astos changed` · `astos status` · `astos explain --symbol X` · `astos hotspots` · `astos dead` · `astos tests --file X`.

## HUBS (maior degree centrality)
- `app/lib/features/explorer/presentation/explorer_page.dart` [dart] deg=10 — dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/widgets/hud_panel.dart`, `app/lib/features/explorer/domain/file_entry.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/presentation/widgets/category_grid.dart`, `app/lib/features/explorer/presentation/widgets/file_tile.dart`, `app/lib/features/explorer/presentation/widgets/path_bar.dart`, `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` (+1)
- `app/lib/core/theme/porte_colors.dart` [dart] deg=7
- `app/lib/core/widgets/hud_panel.dart` [dart] deg=5 — dep: `app/lib/core/theme/chamfered.dart`, `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/porte_theme.dart`
- `app/lib/features/explorer/domain/file_entry.dart` [dart] deg=5
- `app/lib/core/theme/porte_theme.dart` [dart] deg=4 — dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/chamfered.dart`
- `app/lib/features/explorer/presentation/widgets/file_tile.dart` [dart] deg=4 — dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/features/explorer/services/icon_cache.dart`, `app/lib/features/explorer/domain/file_entry.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` [dart] deg=4 — dep: `app/lib/features/terminal/terminal_service.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/domain/file_entry.dart`
- `app/lib/features/explorer/services/file_service.dart` [dart] deg=4 — dep: `app/lib/features/explorer/domain/file_entry.dart`
- `app/lib/core/theme/chamfered.dart` [dart] deg=3
- `app/lib/features/explorer/presentation/widgets/category_grid.dart` [dart] deg=3 — dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/chamfered.dart`
- `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` [dart] deg=3 — dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/widgets/hud_panel.dart`
- `app/lib/main.dart` [dart] deg=3 — dep: `app/lib/core/theme/porte_theme.dart`, `app/lib/features/explorer/presentation/explorer_page.dart`
- `app/test/widget_test.dart` [dart] deg=3 — dep: `app/lib/main.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/domain/file_entry.dart`
- `app/lib/features/explorer/presentation/widgets/path_bar.dart` [dart] deg=2 — dep: `app/lib/core/theme/porte_colors.dart`
- `app/linux/flutter/generated_plugin_registrant.h` [c] deg=2

## CAPABILITIES (hardware/plataforma — quem fala com o quê)
- `camera`: `app/lib/features/explorer/presentation/widgets/category_grid.dart`
- `network`:manifest: `app/android/app/src/debug/AndroidManifest.xml[INTERNET]`, `app/android/app/src/main/AndroidManifest.xml[INTERNET]`, `app/android/app/src/profile/AndroidManifest.xml[INTERNET]`, `app_descompilado/AndroidManifest.xml[ACCESS_NETWORK_STATE]`, `app_descompilado/AndroidManifest.xml[INTERNET]`
- `notifications`:manifest: `app_descompilado/AndroidManifest.xml[POST_NOTIFICATIONS]`
- `storage`:manifest: `app/android/app/src/main/AndroidManifest.xml[MANAGE_EXTERNAL_STORAGE]`, `app/android/app/src/main/AndroidManifest.xml[READ_EXTERNAL_STORAGE]`, `app/android/app/src/main/AndroidManifest.xml[WRITE_EXTERNAL_STORAGE]`, `app_descompilado/AndroidManifest.xml[MANAGE_EXTERNAL_STORAGE]`, `app_descompilado/AndroidManifest.xml[READ_EXTERNAL_STORAGE]`, `app_descompilado/AndroidManifest.xml[WRITE_EXTERNAL_STORAGE]`

## ARQUIVOS
- `app/lib/features/explorer/presentation/explorer_page.dart` [dart] deg=10 :: dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/widgets/hud_panel.dart`, `app/lib/features/explorer/domain/file_entry.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/presentation/widgets/category_grid.dart`, `app/lib/features/explorer/presentation/widgets/file_tile.dart`, `app/lib/features/explorer/presentation/widgets/path_bar.dart`, `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart`, `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` :: ext: `dart:io` :: def: ExplorerPage:L18, createState():L21, _ExplorerPageState:L23, initState():L34, _init():L38, _reload():L51, setState():L53, setState():L59, setState():L64, _navigate():L69, setState():L71, _openEntry():L74 (+14) :: calls: FileService()>`app/lib/features/explorer/services/file_service.dart`, clear()>`app/lib/features/explorer/services/icon_cache.dart`, PorteAppBar()>`app/lib/core/widgets/hud_panel.dart`, IconButton()>`app/lib/core/widgets/hud_panel.dart`, StorageCarousel()>`app/lib/features/explorer/presentation/widgets/storage_carousel.dart`, HudPanel()>`app/lib/core/widgets/hud_panel.dart`, CategoryGrid()>`app/lib/features/explorer/presentation/widgets/category_grid.dart`, PathBar()>`app/lib/features/explorer/presentation/widgets/path_bar.dart`
- `app/lib/core/theme/porte_colors.dart` [dart] deg=7
- `app/lib/core/widgets/hud_panel.dart` [dart] deg=5 :: dep: `app/lib/core/theme/chamfered.dart`, `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/porte_theme.dart` :: todo:1(TODO:L7 o PORTE.) :: def: HudPanel:L8, build():L25, NeonButton:L80, build():L88, PorteAppBar:L126, build():L136, Container():L137, IconButton():L152 :: calls: ClipPath()>`app/lib/features/explorer/presentation/widgets/category_grid.dart`, ChamferedClipper()>`app/lib/core/theme/chamfered.dart`, Row()>`app/lib/features/explorer/presentation/widgets/path_bar.dart`
- `app/lib/features/explorer/domain/file_entry.dart` [dart] deg=5 :: ext: `dart:io` :: def: PorteEntryKind:L5, FileEntry:L6, compareTo():L53
- `app/lib/core/theme/porte_theme.dart` [dart] deg=4 :: dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/chamfered.dart` :: def: buildPorteTheme():L7 :: calls: ChamferedBorder()>`app/lib/core/theme/chamfered.dart`
- `app/lib/features/explorer/presentation/widgets/file_tile.dart` [dart] deg=4 :: dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/features/explorer/services/icon_cache.dart`, `app/lib/features/explorer/domain/file_entry.dart` :: def: formatSize():L6, FileTile:L20, build():L39, Container():L43 :: calls: ListTile()>`app/lib/features/explorer/presentation/widgets/porte_context_menu.dart`, PorteFileIcon()>`app/lib/features/explorer/services/icon_cache.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` [dart] deg=4 :: dep: `app/lib/features/terminal/terminal_service.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/domain/file_entry.dart` :: ext: `dart:io` :: def: showModalBottomSheet():L20, ListTile():L26, ListTile():L50, ListTile():L59, ListTile():L68, TextButton():L80, TextButton():L81, ListTile():L97, TextButton():L108, TextButton():L109 :: calls: TerminalService()>`app/lib/features/terminal/terminal_service.dart`, openTerminal()>`app/lib/features/terminal/terminal_service.dart`, open()>`app/lib/features/crypto/vault_service.dart`, AlertDialog()>`app/lib/features/explorer/presentation/explorer_page.dart`, rename()>`app/lib/features/explorer/services/file_service.dart`, delete()>`app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/services/file_service.dart` [dart] deg=4 :: dep: `app/lib/features/explorer/domain/file_entry.dart` :: ext: `dart:io` :: def: FileOpException:L8, toString():L12, FileService:L14, createFolder():L42, createFile():L48, rename():L54, delete():L68, copy():L77, move():L87, File():L90, _copyDir():L97 :: calls: FileEntry()>`app/lib/features/explorer/domain/file_entry.dart`
- `app/lib/core/theme/chamfered.dart` [dart] deg=3 :: def: ChamferedBorder:L4, _path():L11, scale():L40, ChamferedClipper:L44, getClip():L49, shouldReclip():L64
- `app/lib/features/explorer/presentation/widgets/category_grid.dart` [dart] deg=3 :: dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/theme/chamfered.dart` :: caps: camera :: def: CategoryGrid:L7, build():L23, ClipPath():L38 :: calls: ChamferedClipper()>`app/lib/core/theme/chamfered.dart`
- `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` [dart] deg=3 :: dep: `app/lib/core/theme/porte_colors.dart`, `app/lib/core/widgets/hud_panel.dart` :: ext: `dart:io` :: def: StorageCarousel:L8, build():L27, fmt():L110 :: calls: HudPanel()>`app/lib/core/widgets/hud_panel.dart`, Row()>`app/lib/features/explorer/presentation/widgets/path_bar.dart`, NeonButton()>`app/lib/core/widgets/hud_panel.dart`
- `app/lib/main.dart` [dart] deg=3 :: dep: `app/lib/core/theme/porte_theme.dart`, `app/lib/features/explorer/presentation/explorer_page.dart` :: entry :: def: main():L4, PorteApp:L8, build():L13 :: calls: buildPorteTheme()>`app/lib/core/theme/porte_theme.dart`, ExplorerPage()>`app/lib/features/explorer/presentation/explorer_page.dart`
- `app/test/widget_test.dart` [dart] deg=3 :: dep: `app/lib/main.dart`, `app/lib/features/explorer/services/file_service.dart`, `app/lib/features/explorer/domain/file_entry.dart` :: ext: `dart:io` :: entry :: def: main():L6, testWidgets():L8, test():L13, e():L15, test():L28, expect():L35 :: calls: PorteApp()>`app/lib/main.dart`, FileEntry()>`app/lib/features/explorer/domain/file_entry.dart`, FileService()>`app/lib/features/explorer/services/file_service.dart`, createFolder()>`app/lib/features/explorer/services/file_service.dart`, rename()>`app/lib/features/explorer/services/file_service.dart`, delete()>`app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/widgets/path_bar.dart` [dart] deg=2 :: dep: `app/lib/core/theme/porte_colors.dart` :: def: PathBar:L5, build():L11, _seg():L37, Row():L39
- `app/linux/flutter/generated_plugin_registrant.h` [c] deg=2 :: ext: `<flutter_linux/flutter_linux.h>`
- `app/linux/runner/my_application.cc` [c] deg=2 :: dep: `app/linux/runner/my_application.h`, `app/linux/flutter/generated_plugin_registrant.h` :: ext: `<flutter_linux/flutter_linux.h>`, `<gdk/gdkx.h>` :: def: first_frame_cb():L18, my_application_activate():L23, my_application_local_command_line():L82, my_application_startup():L103, my_application_shutdown():L112, my_application_dispose():L121, my_application_class_init():L127, my_application_init():L136, my_application_new():L138 :: calls: fl_register_plugins()>`app/linux/flutter/generated_plugin_registrant.cc`
- `app/linux/runner/my_application.h` [c] deg=2 :: ext: `<gtk/gtk.h>`
- `app/lib/features/explorer/services/icon_cache.dart` [dart] deg=1 :: ext: `dart:io`, `dart:typed_data` :: def: IconCache:L7, get():L14, put():L16, putBytes():L23, getBytes():L28, invalidate():L30, clear():L35, iconFor():L42, colorFor():L55, PorteFileIcon:L67, build():L74, ClipRRect():L87 (+1) :: calls: File()>`app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/terminal/terminal_service.dart` [dart] deg=1 :: ext: `dart:async`, `dart:io` :: def: TerminalService:L14, openTerminal():L16, _openAndroid():L26, _openDesktop():L60, unawaited():L75
- `app/linux/flutter/generated_plugin_registrant.cc` [c] deg=1 :: dep: `app/linux/flutter/generated_plugin_registrant.h` :: ext: `<url_launcher_linux/url_launcher_plugin.h>` :: def: fl_register_plugins():L11
- `app/linux/runner/main.cc` [c] deg=1 :: dep: `app/linux/runner/my_application.h` :: entry :: def: main():L3 :: calls: my_application_new()>`app/linux/runner/my_application.cc`
- `app/android/app/build.gradle.kts` [kotlin] deg=0 :: ext: `java.util.Properties` :: todo:1(TODO:L25 Specify your own unique Application ID (https://dev)
- `app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` [java] deg=0 :: def: GeneratedPluginRegistrant:L15, registerWith():L17
- `app/android/app/src/main/kotlin/dev/porte/porte/MainActivity.kt` [kotlin] deg=0 :: entry :: def: MainActivity:L9, openTermux():L26
- `app/android/build.gradle.kts` [kotlin] deg=0
- `app/android/settings.gradle.kts` [kotlin] deg=0
- `app/lib/features/crypto/vault_service.dart` [dart] deg=0 :: ext: `dart:convert`, `dart:io`, `dart:typed_data` :: def: VaultService:L13, open():L16, lock():L27, unlock():L41, _key():L23 :: calls: toString()>`app/lib/features/explorer/services/file_service.dart`, File()>`app/lib/features/explorer/services/file_service.dart`
- `app_descompilado/META-INF/services/ax.Ec.H` [c] deg=0

## RISKS (onde o bug provavelmente mora — comece por aqui)
god files (grande/conectado demais): `app/lib/features/explorer/presentation/explorer_page.dart`(loc=295,syms=26,deg=10)
fan-out alto (depende de muitos): `app/lib/features/explorer/presentation/explorer_page.dart`(9)
TODOs: `app/lib/core/widgets/hud_panel.dart`x1(TODO:L7 o PORTE.); `app/android/app/build.gradle.kts`x1(TODO:L25 Specify your own unique Application ID (h)
entrypoints: `app/lib/main.dart`, `app/test/widget_test.dart`, `app/linux/runner/main.cc`, `app/android/app/src/main/kotlin/dev/porte/porte/MainActivity.kt`
órfãos (deg=0, possível morto): `app/android/app/build.gradle.kts`, `app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`, `app/android/build.gradle.kts`, `app/android/settings.gradle.kts`, `app/lib/features/crypto/vault_service.dart`, `app_descompilado/META-INF/services/ax.Ec.H`

## FLUXO (chamadas entre arquivos, top 30)
- `app/lib/core/theme/porte_theme.dart` --ChamferedBorder()--> `app/lib/core/theme/chamfered.dart`
- `app/lib/core/widgets/hud_panel.dart` --ClipPath()--> `app/lib/features/explorer/presentation/widgets/category_grid.dart`
- `app/lib/core/widgets/hud_panel.dart` --ChamferedClipper()--> `app/lib/core/theme/chamfered.dart`
- `app/lib/core/widgets/hud_panel.dart` --Row()--> `app/lib/features/explorer/presentation/widgets/path_bar.dart`
- `app/lib/features/crypto/vault_service.dart` --toString()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/crypto/vault_service.dart` --File()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --FileService()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --clear()--> `app/lib/features/explorer/services/icon_cache.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --PorteAppBar()--> `app/lib/core/widgets/hud_panel.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --IconButton()--> `app/lib/core/widgets/hud_panel.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --StorageCarousel()--> `app/lib/features/explorer/presentation/widgets/storage_carousel.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --HudPanel()--> `app/lib/core/widgets/hud_panel.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --CategoryGrid()--> `app/lib/features/explorer/presentation/widgets/category_grid.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --PathBar()--> `app/lib/features/explorer/presentation/widgets/path_bar.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --formatSize()--> `app/lib/features/explorer/presentation/widgets/file_tile.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --ListTile()--> `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --createFolder()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/explorer_page.dart` --delete()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/widgets/category_grid.dart` --ChamferedClipper()--> `app/lib/core/theme/chamfered.dart`
- `app/lib/features/explorer/presentation/widgets/file_tile.dart` --ListTile()--> `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart`
- `app/lib/features/explorer/presentation/widgets/file_tile.dart` --PorteFileIcon()--> `app/lib/features/explorer/services/icon_cache.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --TerminalService()--> `app/lib/features/terminal/terminal_service.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --openTerminal()--> `app/lib/features/terminal/terminal_service.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --open()--> `app/lib/features/crypto/vault_service.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --AlertDialog()--> `app/lib/features/explorer/presentation/explorer_page.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --rename()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/widgets/porte_context_menu.dart` --delete()--> `app/lib/features/explorer/services/file_service.dart`
- `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` --HudPanel()--> `app/lib/core/widgets/hud_panel.dart`
- `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` --Row()--> `app/lib/features/explorer/presentation/widgets/path_bar.dart`
- `app/lib/features/explorer/presentation/widgets/storage_carousel.dart` --NeonButton()--> `app/lib/core/widgets/hud_panel.dart`
