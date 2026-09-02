/// Same-document navigation through `history.pushState` and `replaceState`
/// fires no browser event, so the history hooks dispatch this one themselves.
const String locationChangeEventType = 'jasprhooks-locationchange';
