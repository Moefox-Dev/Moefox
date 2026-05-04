// Moefox Locale Debugging Script v2
// Run this in Browser Console (Ctrl+Shift+J) to diagnose locale issues

(async function debugLocale() {
  console.log("=== Moefox Locale Debugging v2 ===\n");

  // 1. Check preference
  const requested = Services.prefs.getStringPref("intl.locale.requested", "(not set)");
  console.log("1. intl.locale.requested:", requested);

  // 2. Get LocaleService info
  const ls = Services.locale;
  console.log("\n2. LocaleService info:");
  console.log("   - defaultLocale:", ls.defaultLocale);
  console.log("   - lastFallbackLocale:", ls.lastFallbackLocale);
  console.log("   - Packaged locales:", ls.packagedLocales.join(", "));
  console.log("   - Available locales:", ls.availableLocales.join(", "));
  console.log("   - Requested locales:", ls.requestedLocales.join(", "));
  console.log("   - App locales (negotiated):", ls.appLocalesAsBCP47.join(", "));

  // 3. Check if zh-CN files exist via fetch
  console.log("\n3. Testing zh-CN file access via fetch:");
  const testPaths = [
    "resource://gre/localization/zh-CN/toolkit/global/commonDialog.ftl",
    "resource://gre/localization/zh-CN/toolkit/about/aboutSupport.ftl",
    "resource://app/localization/zh-CN/browser/browser.ftl",
    "resource://app/localization/zh-CN/browser/menubar.ftl",
    "resource://app/localization/zh-CN/browser/browserContext.ftl",
  ];

  for (const path of testPaths) {
    try {
      const response = await fetch(path);
      if (response.ok) {
        const text = await response.text();
        // Show first 100 chars to verify it's Chinese
        const preview = text.substring(0, 150).replace(/\n/g, " ");
        console.log(`   ✓ ${path}`);
        console.log(`     Size: ${text.length} bytes, Preview: ${preview}...`);
      } else {
        console.log(`   ✗ ${path}: HTTP ${response.status}`);
      }
    } catch (e) {
      console.log(`   ✗ ${path}: ${e.message}`);
    }
  }

  // 4. Try to use ChromeUtils to access L10nRegistry
  console.log("\n4. L10nRegistry check:");
  try {
    const { L10nRegistry } = ChromeUtils.importESModule(
      "resource://gre/modules/L10nRegistry.sys.mjs"
    );
    const registry = L10nRegistry.getInstance();
    const sourceNames = registry.getSourceNames();
    console.log("   Sources:", sourceNames.join(", "));
    
    for (const name of sourceNames) {
      const source = registry.getSource(name);
      if (source) {
        console.log(`   - ${name}: locales=[${source.locales.join(",")}] prePath=${source.prePath}`);
      }
    }

    // Try to generate a bundle
    console.log("\n5. Testing bundle generation for zh-CN:");
    const bundles = registry.generateBundlesSync(["zh-CN"], ["browser/browser.ftl"]);
    const bundle = bundles.next();
    if (bundle.value) {
      console.log("   ✓ Bundle created, locales:", [...bundle.value.locales].join(", "));
      // Try to get a message
      const msg = bundle.value.getMessage("urlbar-resolve-resolve");
      console.log("   Sample message 'urlbar-resolve-resolve':", msg ? "found" : "not found");
    } else {
      console.log("   ✗ No bundle created for zh-CN");
    }
  } catch (e) {
    console.log("   Error:", e.message);
    console.log("   Stack:", e.stack);
  }

  // 6. Check actual document localization
  console.log("\n6. Document localization check:");
  try {
    // Check what locale the main document is using
    const start = performance.now();
    console.log("   Current document l10n:");
    if (document.l10n) {
      const resources = await document.l10n.ready;
      console.log("   - l10n ready");
      // Try to format a known message
      const testMsg = await document.l10n.formatValue("appmenu-fxa-header2");
      console.log(`   - Sample formatted message: "${testMsg}"`);
    } else {
      console.log("   - document.l10n not available");
    }
  } catch (e) {
    console.log("   Error:", e.message);
  }

  // 7. Check startup cache
  console.log("\n7. Startup cache info:");
  try {
    const startupInfo = Services.startup;
    console.log("   - wasSilentlyStarted:", startupInfo.wasSilentlyStarted);
    console.log("   - wasRestarted:", startupInfo.wasRestarted);
  } catch (e) {
    console.log("   Error:", e.message);
  }

  // 8. Check for language pack extensions
  console.log("\n8. Installed language packs:");
  try {
    const { AddonManager } = ChromeUtils.importESModule(
      "resource://gre/modules/AddonManager.sys.mjs"
    );
    const langpacks = await AddonManager.getAddonsByTypes(["locale"]);
    if (langpacks.length === 0) {
      console.log("   (none installed - using built-in locales)");
    } else {
      for (const lp of langpacks) {
        console.log(`   - ${lp.id}: ${lp.isActive ? "active" : "inactive"}`);
      }
    }
  } catch (e) {
    console.log("   Error:", e.message);
  }

  console.log("\n=== End of Locale Debugging v2 ===");
})();
