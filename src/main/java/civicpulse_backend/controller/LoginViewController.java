package civicpulse_backend.controller;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * Serves the custom CivicPulse-branded OAuth login page for Spring Security form login.
 */
@Controller
public class LoginViewController {

    @GetMapping(value = "/login", produces = MediaType.TEXT_HTML_VALUE)
    @ResponseBody
    public String renderLoginPage(
            @RequestParam(value = "error", required = false) String error,
            @RequestParam(value = "logout", required = false) String logout,
            @RequestParam(value = "return_to", required = false) String returnTo,
            jakarta.servlet.http.HttpServletRequest request) {

        String effectiveReturnTo = returnTo;
        if (effectiveReturnTo == null || effectiveReturnTo.isBlank()) {
            jakarta.servlet.http.HttpSession session = request.getSession(false);
            if (session != null) {
                effectiveReturnTo = (String) session.getAttribute("OAUTH_AUTHORIZATION_REQUEST_URL");
                if (effectiveReturnTo == null) {
                    org.springframework.security.web.savedrequest.SavedRequest savedReq =
                            (org.springframework.security.web.savedrequest.SavedRequest) session.getAttribute("SPRING_SECURITY_SAVED_REQUEST");
                    if (savedReq != null) {
                        effectiveReturnTo = savedReq.getRedirectUrl();
                    }
                }
            }
        }

        String returnToField = (effectiveReturnTo != null && effectiveReturnTo.contains("/oauth2/authorize"))
                ? "<input type=\"hidden\" name=\"return_to\" value=\"" + org.springframework.web.util.HtmlUtils.htmlEscape(effectiveReturnTo) + "\" />\n"
                : "";

        String errorBanner = (error != null) ? """
            <div class="alert alert-error" role="alert">
                <svg class="alert-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
                </svg>
                <span>Invalid email or password. Please try again.</span>
            </div>
        """ : "";

        String logoutBanner = (logout != null) ? """
            <div class="alert alert-success" role="alert">
                <svg class="alert-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
                </svg>
                <span>You have been signed out successfully.</span>
            </div>
        """ : "";

        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Sign In &middot; CivicPulse</title>
                <link rel="preconnect" href="https://fonts.googleapis.com">
                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
                <style>
                    *, *::before, *::after {
                        box-sizing: border-box;
                        margin: 0;
                        padding: 0;
                    }
                    body {
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        background-color: #F8FAFC;
                        color: #0F172A;
                        min-height: 100vh;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        padding: 24px 16px;
                    }
                    .login-card {
                        background: #FFFFFF;
                        border: 1px solid #E2E8F0;
                        border-radius: 20px;
                        box-shadow: 0 10px 25px -5px rgba(15, 118, 110, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
                        width: 100%;
                        max-width: 420px;
                        padding: 40px 32px;
                    }
                    .brand-header {
                        text-align: center;
                        margin-bottom: 28px;
                    }
                    .logo-badge {
                        width: 56px;
                        height: 56px;
                        background: linear-gradient(135deg, #0F766E 0%, #0D9488 100%);
                        border-radius: 16px;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        margin-bottom: 16px;
                        box-shadow: 0 8px 16px -4px rgba(15, 118, 110, 0.35);
                    }
                    .logo-icon {
                        width: 30px;
                        height: 30px;
                        color: #FFFFFF;
                    }
                    .brand-title {
                        font-size: 24px;
                        font-weight: 700;
                        color: #0F172A;
                        letter-spacing: -0.025em;
                        margin-bottom: 6px;
                    }
                    .brand-subtitle {
                        font-size: 14px;
                        color: #475569;
                        line-height: 1.45;
                    }
                    .alert {
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        padding: 12px 14px;
                        border-radius: 12px;
                        font-size: 13.5px;
                        font-weight: 500;
                        margin-bottom: 20px;
                    }
                    .alert-error {
                        background-color: #FEF2F2;
                        border: 1px solid #FCA5A5;
                        color: #DC2626;
                    }
                    .alert-success {
                        background-color: #F0FDF4;
                        border: 1px solid #86EFAC;
                        color: #16A34A;
                    }
                    .alert-icon {
                        width: 18px;
                        height: 18px;
                        flex-shrink: 0;
                    }
                    .form-group {
                        margin-bottom: 20px;
                    }
                    .form-label {
                        display: block;
                        font-size: 13.5px;
                        font-weight: 600;
                        color: #0F172A;
                        margin-bottom: 7px;
                    }
                    .form-input {
                        width: 100%;
                        padding: 12px 14px;
                        font-size: 15px;
                        font-family: inherit;
                        color: #0F172A;
                        background: #FFFFFF;
                        border: 1.5px solid #E2E8F0;
                        border-radius: 12px;
                        outline: none;
                        transition: all 0.2s ease;
                    }
                    .form-input::placeholder {
                        color: #94A3B8;
                    }
                    .form-input:focus {
                        border-color: #0F766E;
                        box-shadow: 0 0 0 3.5px rgba(15, 118, 110, 0.15);
                    }
                    .btn-submit {
                        width: 100%;
                        padding: 13px;
                        font-size: 15px;
                        font-weight: 600;
                        font-family: inherit;
                        color: #FFFFFF;
                        background-color: #0F766E;
                        border: none;
                        border-radius: 12px;
                        cursor: pointer;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        gap: 8px;
                        transition: background-color 0.2s ease, transform 0.1s ease, box-shadow 0.2s ease;
                        box-shadow: 0 4px 12px rgba(15, 118, 110, 0.25);
                        margin-top: 6px;
                    }
                    .btn-submit:hover {
                        background-color: #0D9488;
                    }
                    .btn-submit:active {
                        transform: scale(0.99);
                    }
                    .btn-icon {
                        width: 17px;
                        height: 17px;
                    }
                    .security-footer {
                        margin-top: 24px;
                        text-align: center;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        gap: 6px;
                        font-size: 12px;
                        color: #94A3B8;
                        font-weight: 500;
                    }
                    .security-icon {
                        width: 14px;
                        height: 14px;
                        color: #94A3B8;
                    }
                </style>
            </head>
            <body>
                <div class="login-card">
                    <div class="brand-header">
                        <div class="logo-badge">
                            <svg class="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                                <path d="M12 8v4"/>
                                <path d="M12 16h.01"/>
                            </svg>
                        </div>
                        <h1 class="brand-title">Welcome to CivicPulse</h1>
                        <p class="brand-subtitle">Sign in securely to track and report civic issues in your area.</p>
                    </div>

                    """ + errorBanner + logoutBanner + """

                    <form method="post" action="/login">
                        """ + returnToField + """
                        <div class="form-group">
                            <label class="form-label" for="username">Email Address</label>
                            <input class="form-input" type="email" id="username" name="username" placeholder="name@example.com" required autofocus autocomplete="username" />
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="password">Password</label>
                            <input class="form-input" type="password" id="password" name="password" placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;" required autocomplete="current-password" />
                        </div>

                        <button type="submit" class="btn-submit">
                            <svg class="btn-icon" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z" clip-rule="evenodd" />
                            </svg>
                            <span>Sign In</span>
                        </button>
                    </form>

                    <div class="security-footer">
                        <svg class="security-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        </svg>
                        <span>Secured by OAuth 2.1 &middot; PKCE enabled</span>
                    </div>
                </div>
            </body>
            </html>
        """;
    }
}
