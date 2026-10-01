/// Small holder so the auth deep-link handler (outside widget context)
/// can tell the router where to land after confirmation / recovery.
class DeepLinkState {
  DeepLinkState._();
  static bool recoveryPending = false;
  static bool justConfirmed = false;
}
