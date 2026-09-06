import Foundation

/// Submits text forms in the background and refreshes a server-rendered region.
///
/// Matching POST forms retain native submission when JavaScript is unavailable.
/// Endpoints must accept URL-encoded fields and return a successful response for
/// `Accept: application/json`, or an error object containing an `errors` string array.
/// After success, Robin fetches the current page and replaces the identified region.
/// Unsubmitted text fields retain their drafts. File-upload forms remain native.
public struct FormSubmissionClientModule: Sendable {
  /// The document identifier of the region containing the forms.
  public let regionID: String
  /// The same-origin path shared by the forms' mutation endpoints.
  public let actionPrefix: String

  /// Creates a form enhancement scoped to one region and endpoint path.
  /// - Parameters:
  ///   - regionID: A nonempty document identifier without whitespace.
  ///   - actionPrefix: An absolute path without a trailing slash, query, or fragment.
  /// - Throws: `BuildError.invalidRuntimeConfiguration` for an invalid scope.
  public init(regionID: String, actionPrefix: String) throws {
    guard !regionID.isEmpty, !regionID.contains(where: \.isWhitespace),
      actionPrefix.hasPrefix("/"), !actionPrefix.contains("\\"),
      !actionPrefix.contains("?"), !actionPrefix.contains("#"),
      !actionPrefix.contains(where: \.isWhitespace),
      actionPrefix.dropFirst().split(separator: "/", omittingEmptySubsequences: false)
        .allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
    else { throw BuildError.invalidRuntimeConfiguration("Invalid form submission scope.") }
    self.regionID = regionID
    self.actionPrefix = actionPrefix
  }

  /// Returns the framework-owned enhancement script.
  /// - Throws: An encoding or build error if the asset cannot be created.
  public func asset() throws -> BuildAsset {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let configuration = String(decoding: try encoder.encode(self), as: UTF8.self)
    let identity = ContentDigest.sha256(Array(configuration.utf8)).prefix(16)
    return try BuildAsset(
      reference: "/robin/forms-\(identity).js", path: "assets/robin-forms-\(identity).js",
      bytes: Array(("(()=>{const config=\(configuration);\n" + Self.source + "\n})();").utf8),
      mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.navigation, selectedBy: "FormSubmissionClientModule"))
  }

  static let source = #"""
    let busy=false,stylesheet;
    document.addEventListener("submit",async event=>{
      const form=event.target,region=document.getElementById(config.regionID);
      if(event.defaultPrevented||!(form instanceof HTMLFormElement)||!region?.contains(form)||form.method!=="post"||form.target||event.submitter?.hasAttribute("formaction")||event.submitter?.hasAttribute("formmethod")||event.submitter?.hasAttribute("formenctype")||event.submitter?.hasAttribute("formtarget")||form.enctype!=="application/x-www-form-urlencoded")return;
      const url=new URL(form.action,location.href);
      if(url.origin!==location.origin||!(url.pathname===config.actionPrefix||url.pathname.startsWith(config.actionPrefix+"/"))||form.querySelector('input[type="file"]'))return;
      event.preventDefault();
      if(busy)return;
      const submitter=event.submitter,body=new URLSearchParams(new FormData(form,submitter)),disabled=submitter?.disabled;
      busy=true;
      let saved=false;
      if(submitter)submitter.disabled=true;
      region.setAttribute("aria-busy","true");
      const report=message=>{
        let status=region.querySelector('[data-robin-form-status]');
        if(!status){status=document.createElement("p");status.setAttribute("data-robin-form-status","");status.setAttribute("role","alert");region.prepend(status)}
        status.textContent=message;
      };
      region.querySelector('[data-robin-form-status]')?.remove();
      try{
        const response=await fetch(url,{method:"POST",body,headers:{Accept:"application/json"},credentials:"same-origin",redirect:"error",signal:AbortSignal.timeout(30000)});
        if(!response.ok){
          const error=await response.json().catch(()=>null);
          throw new Error(Array.isArray(error?.errors)?error.errors.join(" "):response.status===401?"Your session has expired. Sign in again to save your changes.":"Could not save your changes. Please try again.");
        }
        saved=true;
        const page=await fetch(location.href,{headers:{Accept:"text/html"},credentials:"same-origin",cache:"no-store",redirect:"error",signal:AbortSignal.timeout(30000)});
        if(!page.ok)throw new Error();
        const parsed=new DOMParser().parseFromString(await page.text(),"text/html"),replacement=parsed.getElementById(config.regionID);
        if(!replacement)throw new Error();
        // Keep drafts in other forms, including edits made while the request was pending.
        for(const field of region.querySelectorAll("input[id],textarea[id],select[id]")){
          if(field.type==="hidden"||field.type==="file")continue;
          const values=body.getAll(field.name);
          const choice=field.type==="checkbox"||field.type==="radio";
          const unchanged=choice?field.checked===values.includes(field.value):field.multiple?[...field.selectedOptions].map(option=>option.value).join("\0")===values.join("\0"):field.value===body.get(field.name);
          if(field.form===form&&unchanged)continue;
          const next=parsed.getElementById(field.id);
          if(!next||!replacement.contains(next))continue;
          if(choice)next.checked=field.checked;
          else if(field.multiple){const selected=[...field.selectedOptions].map(option=>option.value);for(const option of next.options)option.selected=selected.includes(option.value)}
          else next.value=field.value;
        }
        const active=document.activeElement,restoreFocus=region.contains(active),focusID=active?.id||form.querySelector("input[id],textarea[id],select[id]")?.id;
        const styles=[...parsed.querySelectorAll("style[data-robin-style]")].map(style=>style.textContent).join("\n");
        if(styles){
          if(!stylesheet){stylesheet=new CSSStyleSheet();document.adoptedStyleSheets=[...document.adoptedStyleSheets,stylesheet]}
          stylesheet.replaceSync(styles);
        }
        region.replaceWith(replacement);
        const focus=focusID&&document.getElementById(focusID);
        if(restoreFocus){
          if(focus)focus.focus({preventScroll:true});
          else{replacement.setAttribute("tabindex","-1");replacement.focus({preventScroll:true})}
        }
        const status=document.createElement("p");status.setAttribute("role","status");status.setAttribute("data-robin-form-status","");replacement.prepend(status);status.textContent="Changes saved.";
      }catch(error){
        report(saved?"Your change was saved, but the page could not be updated. Reload to see the latest content.":error instanceof TypeError||error.name==="TimeoutError"?"Could not confirm whether your change was saved. Reload before trying again.":error.message||"Could not save your changes. Please try again.");
      }finally{
        busy=false;region.removeAttribute("aria-busy");if(submitter)submitter.disabled=disabled;
      }
    });
    """#
}

extension FormSubmissionClientModule: Encodable {}
