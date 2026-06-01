## 1. Spec authoring (this thread)

- [ ] 1.1 [SPEC] Write `live-monitoring` capability spec with per-requirement implementation status
- [ ] 1.2 [SPEC] Record cross-references (§6.3/§11 alarm → violation-alarms; §8 video → recording-playback)
- [ ] 1.3 [SPEC] Validate change with `openspec validate spec-live-monitoring --strict`

## 2. Capture frame rate (§7.2)

- [ ] 2.1 [GAP] Raise default capture rate to 10 FPS in `recorder.rs` (currently `fps = 2.0`)
- [ ] 2.2 [GAP] Lift the `fps_to_fraction` clamp ceiling (currently ≤5 FPS) to allow 10 FPS

## 3. Adaptive downscaling (§7.2)

- [ ] 3.1 [GAP] Implement `Recorder::set_quality` to actually re-cap the pipeline (currently a no-op)
- [ ] 3.2 [GAP] Extend profile mapping to carry an FPS target (LOW/MEDIUM/HIGH) and apply it on `server.set-resolution`
- [ ] 3.3 [GAP] Verify proctor grid tiles run at a downscaled profile while the zoomed student runs HIGH

## 4. Connection status visibility (§15)

- [ ] 4.1 [GAP] Surface explicit connected/disconnected status per student in `WebsocketStore` (do not silently drop on `server.update-sentinels`)
- [ ] 4.2 [GAP] Render a disconnected indicator in `ProctoringView` grid tiles

## 5. Latency (§7.2, §11)

- [ ] 5.1 [GAP] Add a measurement spike for end-to-end frame latency
- [ ] 5.2 [GAP] Confirm live display latency ≤ 10s under target load (up to 50 students/exam)

## 6. Verification

- [ ] 6.1 [GAP] Confirm 1080p primary capture and 10 FPS default on each supported platform
- [ ] 6.2 [GAP] Confirm view-only: no control path exists from proctor to sentinel
