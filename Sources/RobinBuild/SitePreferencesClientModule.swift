/// A browser capability for native language and appearance pickers.
///
/// Appearance is stored per origin when browser storage is available. System mode
/// follows the device through CSS, including changes while the page is open.
public struct SitePreferencesClientModule {
  /// Creates the shared preferences asset, loaded before page content is painted.
  /// - Returns: The framework-owned browser script.
  /// - Throws: A build error if the asset configuration is invalid.
  public static func asset() throws -> BuildAsset {
    try BuildAsset(
      reference: "/robin/preferences.js", path: "assets/robin-preferences.js",
      bytes: Array(source.utf8), mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.browserAPI, selectedBy: "SitePreferencesClientModule"))
  }

  static let source = #"""
    (()=>{
      const key="robin-appearance",valid=value=>["system","light","dark"].includes(value);
      let preference="system";
      try{const saved=localStorage.getItem(key);if(valid(saved))preference=saved}catch{}
      const apply=()=>{
        if(preference==="system")delete document.documentElement.dataset.robinAppearance;
        else document.documentElement.dataset.robinAppearance=preference;
        document.querySelectorAll("[data-robin-appearance-picker]").forEach(select=>select.value=preference);
        document.querySelectorAll("[data-robin-appearance-choice]").forEach(button=>button.setAttribute("aria-pressed",String(button.dataset.robinAppearanceChoice===preference)));
      };
      const initialize=()=>{
        apply();
        const parts=location.pathname.split("/");
        document.querySelectorAll("[data-robin-language-link]").forEach(link=>{
          const code=link.dataset.robinLanguageLink;
          if(/^[a-zA-Z0-9-]+$/.test(code)&&parts[1]){
            const url=new URL(location.href),localized=[...parts];localized[1]=code;
            url.pathname=localized.join("/");link.href=url.href;
          }
        });
      };
      initialize();
      document.addEventListener("DOMContentLoaded",initialize);
      addEventListener("pageshow",apply);
      addEventListener("storage",event=>{if(event.key===key||event.key===null){preference=valid(event.newValue)?event.newValue:"system";apply()}});
      document.addEventListener("click",event=>{
        const button=event.target.closest("[data-robin-appearance-choice]");
        if(button&&valid(button.dataset.robinAppearanceChoice)){
          preference=button.dataset.robinAppearanceChoice;apply();try{localStorage.setItem(key,preference)}catch{}
          button.closest("[popover]")?.hidePopover();
        }
      });
      document.addEventListener("change",event=>{
        const select=event.target;
        if(select.matches("[data-robin-appearance-picker]")&&valid(select.value)){
          preference=select.value;apply();try{localStorage.setItem(key,preference)}catch{}
        }
        if(select.matches("[data-robin-language-picker]")){
          const codes=[...select.options].map(option=>option.value),url=new URL(location.href),parts=url.pathname.split("/");
          if(codes.includes(parts[1])&&codes.includes(select.value)&&/^[a-zA-Z0-9-]+$/.test(select.value)){
            parts[1]=select.value;url.pathname=parts.join("/");location.assign(url.href);
          }
        }
      });
    })();
    """#
}
