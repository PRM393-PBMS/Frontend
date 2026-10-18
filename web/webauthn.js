// Khoá ứng dụng trên web bằng Web Authentication API (WebAuthn) của trình duyệt:
// gọi Windows Hello, Touch ID / Face ID, vân tay Android... qua bộ xác thực của thiết bị.
//
// Đây là khoá cục bộ giống local_auth trên điện thoại: chỉ xác nhận người đang
// dùng thiết bị, không thay thế đăng nhập với máy chủ.
(function () {
  var KEY = 'pbms_webauthn_credential';

  function randomBytes(n) {
    var a = new Uint8Array(n);
    crypto.getRandomValues(a);
    return a;
  }

  function toB64url(buf) {
    var bin = '';
    new Uint8Array(buf).forEach(function (b) { bin += String.fromCharCode(b); });
    return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function fromB64url(s) {
    var b64 = s.replace(/-/g, '+').replace(/_/g, '/');
    while (b64.length % 4) b64 += '=';
    var bin = atob(b64);
    var out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  function stored() {
    try { return localStorage.getItem(KEY); } catch (_) { return null; }
  }

  // Kết quả: 'success' | 'canceled' | 'unavailable' | 'failed'
  function classify(err) {
    if (!err) return 'failed';
    if (err.name === 'NotAllowedError' || err.name === 'AbortError') return 'canceled';
    if (err.name === 'NotSupportedError' || err.name === 'SecurityError') return 'unavailable';
    if (err.name === 'InvalidStateError') return 'failed';
    return 'failed';
  }

  window.pbmsWebAuthn = {
    // Trình duyệt có bộ xác thực nền tảng xác minh được người dùng (sinh trắc học / PIN máy).
    isAvailable: function () {
      if (!window.isSecureContext || !window.PublicKeyCredential ||
          !PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable) {
        return Promise.resolve(false);
      }
      return PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
        .catch(function () { return false; });
    },

    // Lần đầu: tạo khoá trên thiết bị (người dùng xác thực sinh trắc học để tạo).
    // Các lần sau: yêu cầu xác thực bằng chính khoá đó.
    authenticate: function (displayName) {
      var credId = stored();
      if (!credId) {
        return navigator.credentials.create({
          publicKey: {
            challenge: randomBytes(32),
            rp: { name: 'PBMS Parking' },
            user: { id: randomBytes(16), name: displayName || 'pbms', displayName: displayName || 'PBMS' },
            pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'required',
              residentKey: 'discouraged'
            },
            timeout: 60000
          }
        }).then(function (cred) {
          if (!cred) return 'failed';
          try { localStorage.setItem(KEY, toB64url(cred.rawId)); } catch (_) {}
          return 'success';
        }, classify);
      }
      return navigator.credentials.get({
        publicKey: {
          challenge: randomBytes(32),
          allowCredentials: [{ type: 'public-key', id: fromB64url(credId) }],
          userVerification: 'required',
          timeout: 60000
        }
      }).then(function (assertion) {
        return assertion ? 'success' : 'failed';
      }, classify);
    },

    // Quên khoá đã tạo (dùng khi người dùng tắt khoá sinh trắc học).
    reset: function () {
      try { localStorage.removeItem(KEY); } catch (_) {}
    }
  };
})();
