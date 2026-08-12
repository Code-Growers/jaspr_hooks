export interface HookPage {
  readonly api: string;
  readonly slug: string;
}

export const hookPages: readonly HookPage[] = [
  {api: 'use', slug: 'custom-hook'},
  {api: 'useState', slug: 'use-state'},
  {api: 'useEffect', slug: 'use-effect'},
  {api: 'usePostFrameEffect', slug: 'use-post-frame-effect'},
  {api: 'useMemoized', slug: 'use-memoized'},
  {api: 'useCallback', slug: 'use-callback'},
  {api: 'useRef', slug: 'use-ref'},
  {api: 'useContext', slug: 'use-context'},
  {api: 'useValueChanged', slug: 'use-value-changed'},
  {api: 'usePrevious', slug: 'use-previous'},
  {api: 'useReducer', slug: 'use-reducer'},
  {api: 'useIsMounted', slug: 'use-is-mounted'},
  {api: 'useDebounced', slug: 'use-debounced'},
  {api: 'useFuture', slug: 'use-future'},
  {api: 'useStream', slug: 'use-stream'},
  {api: 'useStreamController', slug: 'use-stream-controller'},
  {api: 'useOnStreamChange', slug: 'use-on-stream-change'},
  {api: 'useListenable', slug: 'use-listenable'},
  {api: 'useListenableSelector', slug: 'use-listenable-selector'},
  {api: 'useValueNotifier', slug: 'use-value-notifier'},
  {api: 'useValueListenable', slug: 'use-value-listenable'},
  {api: 'useOnListenableChange', slug: 'use-on-listenable-change'},
  {api: 'useDocumentVisibility', slug: 'use-document-visibility'},
  {
    api: 'useOnDocumentVisibilityChange',
    slug: 'use-on-document-visibility-change',
  },
  {api: 'usePreferredColorScheme', slug: 'use-preferred-color-scheme'},
  {
    api: 'useOnPreferredColorSchemeChange',
    slug: 'use-on-preferred-color-scheme-change',
  },
] as const;
