(final: prev: {
  # 51.x requires a newer GNOME stack and changes the D-Bus API.
  # Keep the maintained 50.x branch for the current Cinnamon session.
  gpaste = prev.gpaste.overrideAttrs (
    finalAttrs: old: {
      version = "50.11";
      src = prev.fetchurl {
        url = "https://www.imagination-land.org/files/gpaste/GPaste-${finalAttrs.version}.tar.xz";
        hash = "sha256-RtFKvSuFBuyWbuPCj+ZadFLCK7LCmgJSQwZnszD2Bwo=";
      };

      nativeBuildInputs = builtins.filter (p: p != prev.wrapGAppsHook3) old.nativeBuildInputs ++ [
        prev.wrapGAppsHook4
      ];
      buildInputs = builtins.filter (p: p != prev.gtk3) old.buildInputs ++ [
        prev.libx11
        prev.libxi
      ];

      # Cinnamon keeps the previous sessionPath in LD_LIBRARY_PATH
      # during a live switch. Never load an older libgpaste from it.
      preFixup = (old.preFixup or "") + ''
        gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "$out/lib")
      '';

      # The old fix-paths.patch no longer applies to create_g_settings.
      # Keep schema lookup working when the library is loaded via GIR.
      patches = [ ];
      postPatch = ''
        substituteInPlace src/libgpaste/gpaste/gpaste-settings.c \
          --replace-fail 'return g_settings_new (G_PASTE_SETTINGS_NAME);' \
          '{
            g_autoptr (GSettingsSchemaSource) schema_source = g_settings_schema_source_new_from_directory ("${prev.glib.makeSchemaPath (placeholder "out") "${finalAttrs.pname}-${finalAttrs.version}"}", NULL, FALSE, NULL);
            g_autoptr (GSettingsSchema) schema = g_settings_schema_source_lookup (schema_source, G_PASTE_SETTINGS_NAME, FALSE);
            return g_settings_new_full (schema, NULL, NULL);
          }'

        # GTK < 4.24 lacks the autoptr cleanup used by this upstream test.
        substituteInPlace tests/clipboard/test-clipboard.c \
          --replace-fail 'g_autoptr (GdkContentFormatsBuilder) builder' 'GdkContentFormatsBuilder *builder' \
          --replace-fail 'gdk_content_formats_builder_to_formats (builder)' 'gdk_content_formats_builder_free_to_formats (builder)'
      '';
    }
  );
})
