# Folder skeleton

Layer-shared core, feature-grouped UI. Small enough to navigate, structured
enough to not rot.

```
CSNadeGuide/
  App/
    CSNadeGuideApp.swift          # @main, injects ModelContainer + services
    AppDependencies.swift         # supabase client, auth, share services

  Core/
    Models/
      Throw.swift                 # @Model
      ThrowImage.swift            # @Model, normalized crop + aim
      Enums.swift                 # GameMap, Side, NadeType, ImageRole
      SharedTacticDTO.swift       # Codable share payload
    Geometry/
      NormalizedRect.swift        # 0..1 crop transform + apply helpers
      NormalizedPoint.swift       # 0..1 aim marker + apply helpers
    Persistence/
      ModelContainer+App.swift    # SwiftData container, CloudKit config
    Supabase/
      SupabaseClient.swift        # config, single instance
      AuthService.swift           # Apple/Google idToken sign-in, session
      ShareService.swift          # insert/fetch shared_tactics rows
      StorageService.swift        # up/download images to Storage

  Features/
    Library/
      LibraryView.swift
      LibraryViewModel.swift
      ThrowRowView.swift
    ThrowDetail/
      ThrowDetailView.swift
    Editor/
      CropAimEditorView.swift     # THE core component
      CropAimEditorModel.swift
      CropOverlay.swift
      AimReticle.swift
    Capture/
      PhotoPicker.swift           # PhotosPicker wrapper
    Auth/
      SignInView.swift
      AppleSignInButton.swift
      GoogleSignInButton.swift
    Share/
      ShareLinkBuilder.swift
      ImportTacticView.swift      # the "Save to library" card

  Supporting/
    UniversalLinkRouter.swift     # parses /t/<code>, routes to import
    SeedThrows.swift              # textbook placeholder data

  Resources/
    Assets.xcassets

backend/                          # not shipped in app, kept in repo
  schema.sql
  aasa/apple-app-site-association # served at /.well-known/ on your domain
  web-fallback/index.html         # no-app-installed preview page
```

## Notes

- `AuthService` is a protocol with an Apple impl first. Google and later Steam
  slot in behind it without touching call sites.
- `NormalizedRect` / `NormalizedPoint` carry `apply(to:)` helpers so the editor
  and the detail view share one source of truth for coordinate math.
- Keep image bytes out of view models. Pass `ThrowImage` and resolve lazily.
- `backend/` lives in the same repo but is infra, not app target. Keeps the AASA
  file and fallback page version-controlled next to the schema.
