// audit.js — discover what drives the "Use Strong Password" offer in MobileSafari
// Run: frida -U -n MobileSafari -l audit.js
// Then focus a password/new-password field in Safari and watch the output.

'use strict';

const PATTERNS = [
  /strongpassword/i,
  /automaticstrongpassword/i,
  /generatedpassword/i,
  /passwordsuggestion/i,
  /suggeststrong/i,
  /_allowsstrongpassword/i,
  /automaticpasswordinput/i,
];

function matches(name) {
  return PATTERNS.some(function (re) { return re.test(name); });
}

if (!ObjC.available) {
  console.log('[!] Objective-C runtime not available');
} else {
  console.log('[*] Scanning loaded classes for password-suggestion selectors...');
  const hits = [];

  for (const className in ObjC.classes) {
    let methods;
    try {
      methods = ObjC.classes[className].$ownMethods;
    } catch (e) { continue; }
    for (const m of methods) {
      if (matches(m)) {
        hits.push(className + '  ' + m);
      }
    }
  }

  console.log('[*] Candidate selectors (' + hits.length + '):');
  hits.forEach(function (h) { console.log('    ' + h); });

  // Live-trace the candidates so we see which actually fire on field focus.
  console.log('\n[*] Attaching interceptors. Now focus a password field in Safari...\n');
  hits.forEach(function (h) {
    const parts = h.trim().split(/\s+/);
    const className = parts[0];
    const selectorRaw = parts[1];        // e.g. "- _allowsStrongPasswordSuggestions"
    const kind = selectorRaw.charAt(0);  // '-' or '+'
    const sel = selectorRaw.slice(1);
    try {
      const cls = ObjC.classes[className];
      const impl = (kind === '+' ? cls.$metaClass : cls)[sel].implementation;
      Interceptor.attach(impl, {
        onEnter: function () { console.log('>>> FIRED: ' + kind + '[' + className + ' ' + sel + ']'); },
      });
    } catch (e) { /* skip un-hookable */ }
  });
}
