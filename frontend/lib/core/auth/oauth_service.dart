import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../constants/api_constants.dart';
import '../storage/session_manager.dart';
import 'oauth_exception.dart';
import 'oauth_session.dart';

/// Service managing OAuth 2.0 / 2.1 Authorization Code Flow with PKCE
/// and automatic token refresh with single-flight concurrency protection.
class OAuthService {
  final FlutterAppAuth _appAuth;
  final SessionManager sessionManager;
  final String _clientId;
  final String _redirectUrl;
  final List<String> _scopes;

  // Single-flight in-flight future to prevent concurrent duplicate refresh requests
  Future<OAuthSession>? _inFlightRefresh;

  OAuthService({
    FlutterAppAuth? appAuth,
    required this.sessionManager,
    String? clientId,
    String? redirectUrl,
    List<String>? scopes,
  })  : _appAuth = appAuth ?? const FlutterAppAuth(),
        _clientId = clientId ?? ApiConstants.oauthClientId,
        _redirectUrl = redirectUrl ?? ApiConstants.oauthRedirectUrl,
        _scopes = scopes ?? ApiConstants.oauthScopes;

  /// Gets the discovery URL pointing to Spring Authorization Server's OIDC metadata.
  String get discoveryUrl => ApiConstants.oauthDiscoveryUrl;

  /// Initiates the OAuth 2.1 Authorization Code Flow with PKCE.
  ///
  /// Opens the browser/custom tab for user authentication on the Spring Security login page,
  /// receives the authorization code via deep-link redirect (`civicpulse://oauth2redirect`),
  /// exchanges the code + PKCE code_verifier for access/refresh/ID tokens,
  /// saves the tokens securely into [SessionManager], and returns the [OAuthSession].
  Future<OAuthSession> authorize({
    List<String>? promptValues,
    Map<String, String>? additionalParameters,
  }) async {
    try {
      final effectivePromptValues = promptValues ?? const ['login'];
      final effectiveAdditionalParams = {
        'prompt': 'login',
        ...?additionalParameters,
      };

      if (kDebugMode) {
        debugPrint('[OAuth] === AUTHORIZATION REQUEST START ===');
        debugPrint('[OAuth] Client ID: $_clientId');
        debugPrint('[OAuth] Redirect URI: $_redirectUrl');
        debugPrint('[OAuth] Authorization Endpoint: ${ApiConstants.oauthAuthorizationEndpoint}');
        debugPrint('[OAuth] Scopes: $_scopes');
        debugPrint('[OAuth] promptValues: $effectivePromptValues');
        debugPrint('[OAuth] additionalParameters: $effectiveAdditionalParams');
        debugPrint(
            '[OAuth] Generated Authorization URL params: client_id=$_clientId&redirect_uri=$_redirectUrl&response_type=code&scope=${_scopes.join("+")}&prompt=login');
      }

      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: ApiConstants.oauthAuthorizationEndpoint,
          tokenEndpoint: ApiConstants.oauthTokenEndpoint,
        ),
        scopes: _scopes,
        promptValues: effectivePromptValues,
        additionalParameters: effectiveAdditionalParams,
      );

      final AuthorizationTokenResponse? response =
          await _appAuth.authorizeAndExchangeCode(request);

      if (response == null || response.accessToken == null) {
        if (kDebugMode) {
          debugPrint('[OAuth] Authorization response was null or missing access token (user cancelled)');
        }
        throw OAuthException.userCancelled();
      }

      if (kDebugMode) {
        debugPrint(
            '[OAuth] Authorization successful! (hasAccessToken: true, hasRefreshToken: ${response.refreshToken != null}, hasIdToken: ${response.idToken != null})');
      }

      final session = OAuthSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        idToken: response.idToken,
        accessTokenExpiration: response.accessTokenExpirationDateTime,
        tokenType: response.tokenType ?? 'Bearer',
        scopes: response.scopes,
      );

      // Persist the OAuth session in secure storage
      await sessionManager.saveOAuthSession(session);

      return session;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[OAuth] PlatformException during authorization: code=${e.code}, message=${e.message}');
      }
      if (e.code == 'authorize_and_exchange_code_failed' &&
          (e.message?.contains('cancelled') == true ||
              e.message?.contains('canceled') == true ||
              e.message?.contains('User cancelled') == true)) {
        throw OAuthException.userCancelled();
      }
      throw OAuthException.authorizationFailed(e.message);
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('[OAuth] SocketException during authorization: ${e.message}');
      }
      throw OAuthException.networkError(e.message);
    } on OAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OAuth] Unexpected exception during authorization: $e');
      }
      throw OAuthException.authorizationFailed(e.toString());
    }
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Protected by single-flight synchronization: if multiple concurrent calls request refresh,
  /// they all await the same in-progress network request.
  /// Rotates the refresh token upon successful exchange and saves new credentials securely.
  Future<OAuthSession> refreshAccessToken() async {
    if (_inFlightRefresh != null) {
      return _inFlightRefresh!;
    }

    final future = _performRefresh();
    _inFlightRefresh = future;

    try {
      return await future;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<OAuthSession> _performRefresh() async {
    try {
      final currentRefreshToken = await sessionManager.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        await sessionManager.clearSession();
        throw OAuthException.tokenExchangeFailed('No refresh token available');
      }

      final TokenRequest request = TokenRequest(
        _clientId,
        _redirectUrl,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: ApiConstants.oauthAuthorizationEndpoint,
          tokenEndpoint: ApiConstants.oauthTokenEndpoint,
        ),
        refreshToken: currentRefreshToken,
        scopes: _scopes,
        grantType: GrantType.refreshToken,
      );

      final TokenResponse? response = await _appAuth.token(request);

      if (response == null || response.accessToken == null) {
        await sessionManager.clearSession();
        throw OAuthException.tokenExchangeFailed('Token refresh response was empty');
      }

      final currentIdToken = await sessionManager.getIdToken();
      final newSession = OAuthSession(
        accessToken: response.accessToken!,
        refreshToken: (response.refreshToken != null && response.refreshToken!.isNotEmpty)
            ? response.refreshToken
            : currentRefreshToken,
        idToken: response.idToken ?? currentIdToken,
        accessTokenExpiration: response.accessTokenExpirationDateTime,
        tokenType: response.tokenType ?? 'Bearer',
        scopes: response.scopes ?? _scopes,
      );

      // Persist rotated tokens in secure storage
      await sessionManager.saveOAuthSession(newSession);

      return newSession;
    } on PlatformException catch (e) {
      await sessionManager.clearSession();
      throw OAuthException.tokenExchangeFailed(e.message);
    } on SocketException catch (e) {
      throw OAuthException.networkError(e.message);
    } on OAuthException {
      rethrow;
    } catch (e) {
      await sessionManager.clearSession();
      throw OAuthException.tokenExchangeFailed(e.toString());
    }
  }

  /// Clears the local OAuth tokens and session data.
  Future<void> logout() async {
    await sessionManager.clearSession();
  }
}
