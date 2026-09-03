/// An application's client-side navigation strategy for statically rendered sites.
///
/// `clientNavigation` only affects a Static Site application. A server-rendered application
/// always keeps server-rendered navigation and cross-document View Transitions without shipping
/// a navigation runtime.
public enum ClientNavigation: Equatable, Sendable {
  /// No client navigation runtime ships. Navigating between pages performs a full document load.
  ///
  /// This is the default: a Static Site application ships no Robin client JavaScript unless
  /// `.enabled` is explicitly selected.
  case automatic

  /// A small runtime chunk intercepts same-origin navigation, fetches and swaps the requested
  /// static document, updates history, and runs a same-document View Transition.
  case enabled
}

@_spi(Rendering)
extension ClientNavigation {
  /// The capability-scoped production module emitted for explicitly enabled static navigation.
  public var runtimeModule: String? {
    guard self == .enabled else { return nil }
    return #"""
      const load=async(url,push)=>{try{const response=await fetch(url,{headers:{Accept:"text/html"}});if(!response.ok)throw 0;const next=new DOMParser().parseFromString(await response.text(),"text/html"),wanted=[...next.querySelectorAll('link[data-robin-style]')],current=[...document.querySelectorAll('link[data-robin-style]')],have=new Set(current.map(link=>link.href));await Promise.all(wanted.filter(link=>!have.has(link.href)).map(link=>new Promise((resolve,reject)=>{const copy=link.cloneNode();copy.onload=resolve;copy.onerror=reject;document.head.append(copy)})));const swap=()=>{document.title=next.title;document.documentElement.lang=next.documentElement.lang;document.body.replaceWith(next.body);const keep=new Set(wanted.map(link=>link.href));current.filter(link=>!keep.has(link.href)).forEach(link=>link.remove());if(push)history.pushState({},"",url)};document.startViewTransition?document.startViewTransition(swap):swap()}catch{location.assign(url)}};
      addEventListener("click",event=>{const link=event.target.closest("a[href]");if(!link||event.defaultPrevented||event.button!==0||event.metaKey||event.ctrlKey||event.shiftKey||event.altKey||link.target||link.download)return;const url=new URL(link.href,location.href);if(url.origin!==location.origin)return;event.preventDefault();load(url.href,true)});
      addEventListener("popstate",()=>load(location.href,false));
      """#
  }
}
