import Foundation
import SwiftData

/// Seeds and merges the exercise library.
///
/// PR 3 expands PR 2's 21-exercise starter set to ~150 exercises and
/// switches to a versioned merge migration:
/// - Existing rows (matched by `name`) are updated in place — their
///   `PersistentIdentifier` is preserved so PR 2 `WorkoutExercise`
///   references stay intact.
/// - New rows are inserted.
/// - **Nothing is deleted.** Removed entries (and any future user-created
///   exercises) live on so historical workouts remain valid.
///
/// To roll a future change: add new entries to `starterSet`, bump
/// `currentVersion`. Merge re-runs once on next launch.
@MainActor
enum SeedData {

    private static let currentVersion = 2
    private static let versionKey = "seedDataVersion"

    static func seedIfNeeded(_ context: ModelContext) {
        let lastVersion = UserDefaults.standard.integer(forKey: versionKey)
        guard lastVersion < currentVersion else { return }
        merge(into: context)
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    private static func merge(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let byName = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })

        for spec in starterSet {
            if let row = byName[spec.name] {
                row.bodyPart = spec.bodyPart
                row.equipment = spec.equipment
                row.category = spec.category
                row.defaultRestSeconds = spec.defaultRestSeconds
                row.instructions = spec.instructions
            } else {
                context.insert(Exercise(
                    name: spec.name,
                    bodyPart: spec.bodyPart,
                    equipment: spec.equipment,
                    category: spec.category,
                    defaultRestSeconds: spec.defaultRestSeconds,
                    instructions: spec.instructions
                ))
            }
        }
        try? context.save()
    }

    // MARK: - Spec

    private struct Spec {
        let name: String
        let bodyPart: String
        let equipment: String
        let category: String
        let defaultRestSeconds: Int
        let instructions: String
    }

    /// Every exercise lives here. Order doesn't matter for storage —
    /// the Library tab and picker sort/group at query time.
    private static let starterSet: [Spec] = [

        // MARK: Chest

        .init(name: "Bench Press", bodyPart: "Chest", equipment: "Barbell", category: "push", defaultRestSeconds: 150,
              instructions: "Lie flat on a bench. Lower the bar to mid-chest with a controlled tempo, then drive through the chest to press it back up."),
        .init(name: "Incline Barbell Bench Press", bodyPart: "Chest", equipment: "Barbell", category: "push", defaultRestSeconds: 150,
              instructions: "Set the bench to 30–45°. Lower the bar to upper chest and press straight up to bias the upper pecs."),
        .init(name: "Decline Bench Press", bodyPart: "Chest", equipment: "Barbell", category: "push", defaultRestSeconds: 120,
              instructions: "Decline bench around 15°. Lower to lower chest; emphasizes lower pec fibers."),
        .init(name: "Dumbbell Bench Press", bodyPart: "Chest", equipment: "Dumbbell", category: "push", defaultRestSeconds: 120,
              instructions: "Press dumbbells from chest height; let them travel slightly inward at the top for a deeper stretch."),
        .init(name: "Incline Dumbbell Press", bodyPart: "Chest", equipment: "Dumbbell", category: "push", defaultRestSeconds: 120,
              instructions: "30–45° incline. Press dumbbells up and slightly together to bias the upper chest."),
        .init(name: "Decline Dumbbell Press", bodyPart: "Chest", equipment: "Dumbbell", category: "push", defaultRestSeconds: 120,
              instructions: "Decline bench. Press dumbbells from low-chest position; stretch the lower pecs at the bottom."),
        .init(name: "Dumbbell Fly", bodyPart: "Chest", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Slight bend in the elbow held throughout. Lower with control until you feel a stretch, then squeeze the chest to bring the dumbbells together."),
        .init(name: "Incline Dumbbell Fly", bodyPart: "Chest", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "30–45° incline. Open arms wide with a soft elbow bend; squeeze chest to close."),
        .init(name: "Cable Fly", bodyPart: "Chest", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Set pulleys at chest height. Step forward, soft elbow bend, sweep handles together in front of you."),
        .init(name: "Cable Crossover", bodyPart: "Chest", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "High pulleys. Pull handles down and across the body; emphasize the squeeze at the bottom."),
        .init(name: "Pec Deck", bodyPart: "Chest", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Forearms on the pads. Squeeze chest to bring pads together; control the negative."),
        .init(name: "Chest Press Machine", bodyPart: "Chest", equipment: "Machine", category: "push", defaultRestSeconds: 90,
              instructions: "Adjust seat so handles align with mid-chest. Press out, control the return."),
        .init(name: "Incline Chest Press Machine", bodyPart: "Chest", equipment: "Machine", category: "push", defaultRestSeconds: 90,
              instructions: "Inclined press path biased toward upper chest. Keep shoulder blades retracted."),
        .init(name: "Smith Machine Bench Press", bodyPart: "Chest", equipment: "Smith Machine", category: "push", defaultRestSeconds: 120,
              instructions: "Locked bar path lets you push close to failure safely. Position the bench so the bar lowers to mid-chest."),
        .init(name: "Push-Up", bodyPart: "Chest", equipment: "Bodyweight", category: "push", defaultRestSeconds: 60,
              instructions: "Body in a straight line, hands shoulder-width. Lower until chest is just above the floor; push back to start."),
        .init(name: "Incline Push-Up", bodyPart: "Chest", equipment: "Bodyweight", category: "push", defaultRestSeconds: 60,
              instructions: "Hands on a bench or box. Easier variant; eases shoulder demand."),
        .init(name: "Decline Push-Up", bodyPart: "Chest", equipment: "Bodyweight", category: "push", defaultRestSeconds: 60,
              instructions: "Feet elevated on a bench. Bias upper chest and front delts."),
        .init(name: "Dumbbell Pullover", bodyPart: "Chest", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 90,
              instructions: "Lying perpendicular on a bench, lower a dumbbell behind your head with a slight elbow bend; pull it back over the chest using the lats and chest."),

        // MARK: Back

        .init(name: "Conventional Deadlift", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 180,
              instructions: "Hip-width stance, bar over mid-foot. Hinge to grip; drive through the floor with a neutral spine until lockout."),
        .init(name: "Sumo Deadlift", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 180,
              instructions: "Wide stance, hands inside the knees. Sit into the hips and drive through the floor; biases adductors and quads more than conventional."),
        .init(name: "Romanian Deadlift", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 150,
              instructions: "Soft knee bend held. Push hips back to lower the bar along the legs; stand by squeezing the glutes."),
        .init(name: "Stiff-Leg Deadlift", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 150,
              instructions: "Knees nearly locked. Lower the bar with a hard hamstring stretch; rise by extending the hips."),
        .init(name: "Trap Bar Deadlift", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 180,
              instructions: "Stand inside the trap bar. Centered load makes a more vertical pull — friendlier on the lower back than conventional."),
        .init(name: "Barbell Row", bodyPart: "Back", equipment: "Barbell", category: "pull", defaultRestSeconds: 120,
              instructions: "Hinge to ~45°. Row the bar to your lower chest; control the descent without rounding the spine."),
        .init(name: "Pendlay Row", bodyPart: "Back", equipment: "Barbell", category: "pull", defaultRestSeconds: 120,
              instructions: "Bar resets on the floor between every rep. Explosive concentric, dead pause at bottom."),
        .init(name: "Yates Row", bodyPart: "Back", equipment: "Barbell", category: "pull", defaultRestSeconds: 120,
              instructions: "More upright torso (~70°) and underhand grip. Pulls toward the lower chest — heavier loads possible."),
        .init(name: "T-Bar Row", bodyPart: "Back", equipment: "Machine", category: "pull", defaultRestSeconds: 120,
              instructions: "Straddle the T-bar with a chest pad. Row the handles to the chest; squeeze the upper back at the top."),
        .init(name: "Dumbbell Row", bodyPart: "Back", equipment: "Dumbbell", category: "pull", defaultRestSeconds: 90,
              instructions: "One knee and hand on a bench. Row the dumbbell toward the hip; let it travel slightly back, not just up."),
        .init(name: "Chest-Supported Dumbbell Row", bodyPart: "Back", equipment: "Dumbbell", category: "pull", defaultRestSeconds: 90,
              instructions: "Face down on an incline bench. Row both dumbbells to your sides; isolates the upper back without lower-back strain."),
        .init(name: "Cable Row", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 90,
              instructions: "Standing or seated. Pull the handle to your lower ribs with elbows tight; control the eccentric."),
        .init(name: "Seated Cable Row", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 90,
              instructions: "Knees soft, chest up. Pull the handle to the navel; squeeze the shoulder blades together at the end."),
        .init(name: "Single-Arm Cable Row", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 60,
              instructions: "One handle, slight torso rotation allowed. Lets you target one side at a time and feel the lat stretch."),
        .init(name: "Meadows Row", bodyPart: "Back", equipment: "Barbell", category: "pull", defaultRestSeconds: 90,
              instructions: "Single-arm landmine row. Standing at 90° to the bar; row to the hip with a powerful hinge."),
        .init(name: "Lat Pulldown", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 90,
              instructions: "Slight backward lean. Pull the bar to your upper chest; lead with the elbows, not the wrists."),
        .init(name: "Wide-Grip Lat Pulldown", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 90,
              instructions: "Hands wider than shoulder-width. Pulls bias outer-lat and upper-back development."),
        .init(name: "Close-Grip Lat Pulldown", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 90,
              instructions: "Neutral or close grip. Greater range of motion at the bottom; biases lower lats."),
        .init(name: "Pull-Up", bodyPart: "Back", equipment: "Bodyweight", category: "pull", defaultRestSeconds: 120,
              instructions: "Overhand grip, slightly wider than shoulders. Pull until the chin clears the bar; full hang at the bottom."),
        .init(name: "Chin-Up", bodyPart: "Back", equipment: "Bodyweight", category: "pull", defaultRestSeconds: 120,
              instructions: "Underhand grip. Greater bicep involvement; chin clears the bar at the top."),
        .init(name: "Neutral-Grip Pull-Up", bodyPart: "Back", equipment: "Bodyweight", category: "pull", defaultRestSeconds: 120,
              instructions: "Palms facing each other. Joint-friendly and lat-focused."),
        .init(name: "Inverted Row", bodyPart: "Back", equipment: "Bodyweight", category: "pull", defaultRestSeconds: 90,
              instructions: "Bar at hip height in a rack. Pull chest to the bar with a straight body; scaled by foot position."),
        .init(name: "Face Pull", bodyPart: "Back", equipment: "Cable", category: "pull", defaultRestSeconds: 60,
              instructions: "Rope at face height. Pull toward your face with elbows high; great for rear delts and upper-back posture."),
        .init(name: "Cable Pullover", bodyPart: "Back", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Rope or bar at the high pulley. With straight arms, pull down to your hips; isolates the lats."),
        .init(name: "Straight-Arm Pulldown", bodyPart: "Back", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Same path as a cable pullover with a straight bar. Drive through the lats with locked elbows."),
        .init(name: "Banded Pull-Apart", bodyPart: "Back", equipment: "Bodyweight", category: "pull", defaultRestSeconds: 30,
              instructions: "Resistance band at chest height. Pull arms apart until the band touches your sternum — high-rep upper-back work."),

        // MARK: Shoulders

        .init(name: "Overhead Press", bodyPart: "Shoulders", equipment: "Barbell", category: "push", defaultRestSeconds: 150,
              instructions: "Standing, bar at shoulder level. Press overhead while keeping the core braced and ribs down; finish with the bar over the mid-foot."),
        .init(name: "Push Press", bodyPart: "Shoulders", equipment: "Barbell", category: "push", defaultRestSeconds: 150,
              instructions: "Quarter-dip from the legs to start the bar moving, then press overhead. Lets you handle heavier loads than a strict press."),
        .init(name: "Seated Overhead Press", bodyPart: "Shoulders", equipment: "Barbell", category: "push", defaultRestSeconds: 120,
              instructions: "Upright bench. Strict pressing without leg drive — pure shoulder work."),
        .init(name: "Dumbbell Shoulder Press", bodyPart: "Shoulders", equipment: "Dumbbell", category: "push", defaultRestSeconds: 120,
              instructions: "Standing or seated. Greater range of motion than a barbell; let the dumbbells touch lightly overhead."),
        .init(name: "Seated Dumbbell Press", bodyPart: "Shoulders", equipment: "Dumbbell", category: "push", defaultRestSeconds: 120,
              instructions: "Bench upright, back supported. Press dumbbells overhead with a slight inward arc."),
        .init(name: "Arnold Press", bodyPart: "Shoulders", equipment: "Dumbbell", category: "push", defaultRestSeconds: 90,
              instructions: "Start with palms facing you at shoulder height. Rotate as you press up; reverse on the descent."),
        .init(name: "Lateral Raise", bodyPart: "Shoulders", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Soft elbow bend held. Raise the dumbbells out to the sides until just below shoulder height; lead with the elbows."),
        .init(name: "Cable Lateral Raise", bodyPart: "Shoulders", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Low pulley, single arm. Constant tension across the full range; lean slightly away from the cable."),
        .init(name: "Machine Lateral Raise", bodyPart: "Shoulders", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Forearms or upper arms against the pads. Lift to shoulder height with a controlled tempo."),
        .init(name: "Front Raise", bodyPart: "Shoulders", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Raise dumbbells in front of you to shoulder height with straight arms; control the descent."),
        .init(name: "Cable Front Raise", bodyPart: "Shoulders", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Low pulley behind you. Raise the handle in front to shoulder height; constant tension on the front delts."),
        .init(name: "Reverse Fly", bodyPart: "Shoulders", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hinge at the hips with a flat back. Open the arms out to the sides; squeeze the rear delts at the top."),
        .init(name: "Cable Reverse Fly", bodyPart: "Shoulders", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Cables crossed at chest height. Pull arms out and back; emphasizes rear-delt squeeze at end-range."),
        .init(name: "Reverse Pec Deck", bodyPart: "Shoulders", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Face into the machine. Pull the handles out and back; isolates the rear delts."),
        .init(name: "Upright Row", bodyPart: "Shoulders", equipment: "Barbell", category: "pull", defaultRestSeconds: 90,
              instructions: "Hands shoulder-width or slightly wider on the bar. Pull to the upper chest with elbows leading; stop if the shoulders feel pinched."),
        .init(name: "Cable Upright Row", bodyPart: "Shoulders", equipment: "Cable", category: "pull", defaultRestSeconds: 60,
              instructions: "Rope or straight bar from a low pulley. Pull to chin level; smoother joint feel than the barbell version."),
        .init(name: "Smith Machine Shoulder Press", bodyPart: "Shoulders", equipment: "Smith Machine", category: "push", defaultRestSeconds: 90,
              instructions: "Bench upright in the Smith. Locked path lets you press hard without spotter."),
        .init(name: "Shoulder Press Machine", bodyPart: "Shoulders", equipment: "Machine", category: "push", defaultRestSeconds: 90,
              instructions: "Adjust the seat so handles align with the shoulders. Press up and slightly inward; control the negative."),

        // MARK: Arms — Biceps

        .init(name: "Bicep Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Dumbbells at sides. Curl up while keeping elbows pinned; rotate palms up at the top for full bicep contraction."),
        .init(name: "Hammer Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Neutral grip throughout (palms facing each other). Curl up keeping elbows tight; biases brachialis and forearms."),
        .init(name: "Barbell Curl", bodyPart: "Arms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Underhand grip, shoulder-width. Curl without swinging the torso; squeeze the biceps at the top."),
        .init(name: "EZ Bar Curl", bodyPart: "Arms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Slightly angled grip relieves wrist strain. Strict curl with elbows pinned to the sides."),
        .init(name: "Incline Dumbbell Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Bench at 45–60°. The arms hang behind the body, increasing the bicep stretch at the bottom."),
        .init(name: "Concentration Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Seated, elbow braced against the inner thigh. Strict single-arm curl; great for the bicep peak."),
        .init(name: "Preacher Curl", bodyPart: "Arms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Triceps on the pad, fully extend the arm at the bottom. Curl up without lifting the elbows off the pad."),
        .init(name: "Cable Curl", bodyPart: "Arms", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Straight bar or rope on a low pulley. Constant tension on the biceps across the full range."),
        .init(name: "Cable Hammer Curl", bodyPart: "Arms", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Rope attachment, neutral grip. Pull elbows back at the top to add a forearm contraction."),
        .init(name: "Spider Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Face down on an incline bench. Arms hang straight; strict curl with no body english."),
        .init(name: "Zottman Curl", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Curl with palms up; rotate to palms down at the top and lower with that grip. Biceps + forearm combo."),
        .init(name: "Drag Curl", bodyPart: "Arms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Pull the bar straight up along the torso, elbows traveling back. Targets the long head of the biceps."),

        // MARK: Arms — Triceps

        .init(name: "Tricep Pushdown", bodyPart: "Arms", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Straight bar at high pulley. Push down with elbows pinned to the ribs; full lockout at the bottom."),
        .init(name: "Rope Pushdown", bodyPart: "Arms", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Rope at high pulley. Spread the ends apart at the bottom for an extra contraction."),
        .init(name: "Skull Crusher", bodyPart: "Arms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Lying flat with EZ bar. Lower toward the forehead with elbows fixed; extend back to the start."),
        .init(name: "Close-Grip Bench Press", bodyPart: "Arms", equipment: "Barbell", category: "push", defaultRestSeconds: 90,
              instructions: "Hands shoulder-width. Press with elbows tucked tight to the body; emphasizes triceps over chest."),
        .init(name: "Overhead Tricep Extension", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hold one dumbbell with both hands behind the head. Keep elbows narrow as you press up; biases the long head."),
        .init(name: "Cable Overhead Extension", bodyPart: "Arms", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Face away from a high pulley with a rope. Press overhead and forward; great long-head stretch."),
        .init(name: "Tricep Dip", bodyPart: "Arms", equipment: "Bodyweight", category: "push", defaultRestSeconds: 90,
              instructions: "Parallel bars, body upright. Lower until elbows reach 90°; press through the palms to lock out."),
        .init(name: "Bench Dip", bodyPart: "Arms", equipment: "Bodyweight", category: "push", defaultRestSeconds: 60,
              instructions: "Hands behind on a bench, feet on the floor or another bench. Lower until elbows reach 90°; scale by weighting the lap."),
        .init(name: "Diamond Push-Up", bodyPart: "Arms", equipment: "Bodyweight", category: "push", defaultRestSeconds: 60,
              instructions: "Hands form a diamond shape under the chest. Lower with elbows tight; biases the triceps."),
        .init(name: "Tricep Kickback", bodyPart: "Arms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hinge at hips, upper arm parallel to the floor. Extend at the elbow; squeeze hard at the top."),

        // MARK: Legs (Quads + Hamstrings + miscellaneous)

        .init(name: "Back Squat", bodyPart: "Legs", equipment: "Barbell", category: "squat", defaultRestSeconds: 180,
              instructions: "Bar across the upper traps. Sit back and down until thighs reach parallel; drive through the floor to stand."),
        .init(name: "Front Squat", bodyPart: "Legs", equipment: "Barbell", category: "squat", defaultRestSeconds: 150,
              instructions: "Bar racked on the front delts. More upright torso; greater quad demand than a back squat."),
        .init(name: "Box Squat", bodyPart: "Legs", equipment: "Barbell", category: "squat", defaultRestSeconds: 150,
              instructions: "Squat down to a box behind you; pause briefly without releasing tension, then drive up."),
        .init(name: "Pause Squat", bodyPart: "Legs", equipment: "Barbell", category: "squat", defaultRestSeconds: 180,
              instructions: "2–3 second pause at the bottom. Builds bottom-end strength and reinforces position under load."),
        .init(name: "Goblet Squat", bodyPart: "Legs", equipment: "Dumbbell", category: "squat", defaultRestSeconds: 120,
              instructions: "Hold a dumbbell at chest height. Squat to depth keeping the chest up; great for reinforcing pattern."),
        .init(name: "Bulgarian Split Squat", bodyPart: "Legs", equipment: "Dumbbell", category: "lunge", defaultRestSeconds: 90,
              instructions: "Rear foot elevated on a bench. Descend into a deep lunge on the front leg; drive through the front heel."),
        .init(name: "Walking Lunge", bodyPart: "Legs", equipment: "Dumbbell", category: "lunge", defaultRestSeconds: 90,
              instructions: "Step forward, drop into a lunge, then bring the back leg through to step out the next rep. Keep torso upright."),
        .init(name: "Reverse Lunge", bodyPart: "Legs", equipment: "Dumbbell", category: "lunge", defaultRestSeconds: 90,
              instructions: "Step backward into a lunge. More knee-friendly than forward lunges; biases the front-leg glute."),
        .init(name: "Step-Up", bodyPart: "Legs", equipment: "Dumbbell", category: "lunge", defaultRestSeconds: 60,
              instructions: "Drive off the foot on the bench, push the hips through, step back down softly."),
        .init(name: "Barbell Lunge", bodyPart: "Legs", equipment: "Barbell", category: "lunge", defaultRestSeconds: 90,
              instructions: "Bar across the upper back. Step forward (or backward) into a lunge; control the knee path over the toes."),
        .init(name: "Leg Press", bodyPart: "Legs", equipment: "Machine", category: "squat", defaultRestSeconds: 120,
              instructions: "Feet shoulder-width on the platform. Lower until knees approach the chest; drive back without locking out the knees hard."),
        .init(name: "Hack Squat", bodyPart: "Legs", equipment: "Machine", category: "squat", defaultRestSeconds: 120,
              instructions: "Shoulders against the pads. Squat to depth; emphasizes quads with a stable torso."),
        .init(name: "Smith Machine Squat", bodyPart: "Legs", equipment: "Smith Machine", category: "squat", defaultRestSeconds: 120,
              instructions: "Bar locked on a vertical track. Position feet slightly forward; depth is controlled by stance and ROM."),
        .init(name: "Belt Squat", bodyPart: "Legs", equipment: "Machine", category: "squat", defaultRestSeconds: 120,
              instructions: "Belt around the hips, load hangs between the legs. Spinal-decompression-friendly squat pattern."),
        .init(name: "Single-Leg Press", bodyPart: "Legs", equipment: "Machine", category: "squat", defaultRestSeconds: 90,
              instructions: "One foot on the platform centered. Drive through the heel; slow eccentric to feel the quad stretch."),
        .init(name: "Pistol Squat", bodyPart: "Legs", equipment: "Bodyweight", category: "squat", defaultRestSeconds: 60,
              instructions: "Single-leg squat with the other leg extended forward. Demands extreme balance, mobility, and strength."),
        .init(name: "Cossack Squat", bodyPart: "Legs", equipment: "Bodyweight", category: "squat", defaultRestSeconds: 60,
              instructions: "Wide stance. Shift to one side, lowering into a deep lateral squat; opposite leg straight."),
        .init(name: "Leg Extension", bodyPart: "Legs", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Pads on the lower shins. Extend at the knees; squeeze quads at the top, control the descent."),
        .init(name: "Lying Leg Curl", bodyPart: "Legs", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Face down. Curl heels toward the glutes; full range of motion, control the negative."),
        .init(name: "Seated Leg Curl", bodyPart: "Legs", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Knees fixed at the pad's pivot. Curl down through the full range; biases the long head of the hamstring."),
        .init(name: "Standing Leg Curl", bodyPart: "Legs", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Single-leg work. Curl the heel toward the glute with control; full extension at the bottom."),
        .init(name: "Nordic Hamstring Curl", bodyPart: "Legs", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 90,
              instructions: "Knees padded, ankles anchored. Lower the torso forward with hamstrings firing eccentrically; brutal."),
        .init(name: "Glute-Ham Raise", bodyPart: "Legs", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 90,
              instructions: "GHD pad. Lower the torso with straight hamstrings; raise back via knee flexion."),
        .init(name: "Good Morning", bodyPart: "Legs", equipment: "Barbell", category: "hinge", defaultRestSeconds: 90,
              instructions: "Bar on the upper back. Soft knees, hinge at the hips until torso is parallel; rise by extending the hips."),
        .init(name: "Single-Leg RDL", bodyPart: "Legs", equipment: "Dumbbell", category: "hinge", defaultRestSeconds: 90,
              instructions: "Hinge on one leg, opposite leg trailing in line with the torso. Reach toward the floor; rise by squeezing the glute."),

        // MARK: Glutes

        .init(name: "Hip Thrust", bodyPart: "Glutes", equipment: "Barbell", category: "hinge", defaultRestSeconds: 120,
              instructions: "Upper back on a bench, bar across the hips. Drive hips up; full lockout with a glute squeeze."),
        .init(name: "Dumbbell Hip Thrust", bodyPart: "Glutes", equipment: "Dumbbell", category: "hinge", defaultRestSeconds: 90,
              instructions: "Single dumbbell across the hips. Same drive pattern as a barbell hip thrust; lighter loading."),
        .init(name: "Single-Leg Hip Thrust", bodyPart: "Glutes", equipment: "Bodyweight", category: "hinge", defaultRestSeconds: 60,
              instructions: "One foot on the floor, the other leg lifted. Drive through the working heel for a full hip extension."),
        .init(name: "Glute Bridge", bodyPart: "Glutes", equipment: "Bodyweight", category: "hinge", defaultRestSeconds: 60,
              instructions: "Lying with knees bent. Drive the hips up by squeezing the glutes; pause at the top."),
        .init(name: "Cable Pull-Through", bodyPart: "Glutes", equipment: "Cable", category: "hinge", defaultRestSeconds: 90,
              instructions: "Face away from a low pulley with a rope between the legs. Hinge back, then drive hips forward; glute-focused hinge."),
        .init(name: "Cable Glute Kickback", bodyPart: "Glutes", equipment: "Cable", category: "isolation", defaultRestSeconds: 60,
              instructions: "Ankle strap on a low pulley. Kick the leg straight back; squeeze the glute at end-range."),
        .init(name: "Donkey Kick", bodyPart: "Glutes", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 30,
              instructions: "On hands and knees. Press the heel toward the ceiling with a bent knee; hip extension only."),
        .init(name: "Fire Hydrant", bodyPart: "Glutes", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 30,
              instructions: "On hands and knees. Lift the bent knee out to the side; targets glute medius."),
        .init(name: "Banded Glute Bridge", bodyPart: "Glutes", equipment: "Bodyweight", category: "hinge", defaultRestSeconds: 60,
              instructions: "Loop a band above the knees. Drive hips up while pressing the knees out; activates glute medius."),
        .init(name: "Frog Pump", bodyPart: "Glutes", equipment: "Bodyweight", category: "hinge", defaultRestSeconds: 30,
              instructions: "Soles of feet together, knees splayed. Drive hips up; high-rep glute burnout."),
        .init(name: "Sumo Squat", bodyPart: "Glutes", equipment: "Barbell", category: "squat", defaultRestSeconds: 120,
              instructions: "Wide stance, toes pointed out. Sit straight down; biases inner quads and glutes."),
        .init(name: "Reverse Hyper", bodyPart: "Glutes", equipment: "Machine", category: "hinge", defaultRestSeconds: 60,
              instructions: "Hips on the pad. Extend the legs back and up using the glutes and hamstrings; spinal traction is a bonus."),

        // MARK: Core

        .init(name: "Plank", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Forearms on the floor, body in a straight line from head to heels. Brace the core; do not let the hips sag or pike."),
        .init(name: "Side Plank", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "On one forearm, body on its side. Drive the bottom hip up to align head-to-feet."),
        .init(name: "Hanging Leg Raise", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Hang from a bar. Raise straight legs to horizontal (or higher); control the descent — no swinging."),
        .init(name: "Hanging Knee Raise", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Hang from a bar. Bring the knees up toward the chest with controlled tempo. Easier scaling of the leg raise."),
        .init(name: "Cable Crunch", bodyPart: "Core", equipment: "Cable", category: "core", defaultRestSeconds: 60,
              instructions: "Kneel facing a high pulley with a rope behind your head. Crunch by flexing the spine; drive elbows to the floor."),
        .init(name: "Decline Sit-Up", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Decline bench, ankles secured. Curl up to touch the knees; control the descent."),
        .init(name: "Russian Twist", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Sit with knees bent, lean back slightly. Rotate the torso side to side; weight optional."),
        .init(name: "Ab Wheel Rollout", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Knees on the floor (or feet for harder). Roll the wheel forward keeping a hard brace; pull back to start."),
        .init(name: "Dead Bug", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 30,
              instructions: "On your back, opposite arm and leg extended at a time while keeping the lower back pressed into the floor."),
        .init(name: "Bird Dog", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 30,
              instructions: "On hands and knees. Extend opposite arm and leg; pause and switch. Anti-rotation core work."),
        .init(name: "Hollow Hold", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "On your back. Lift shoulder blades and legs off the floor; lower back stays pressed down."),
        .init(name: "Pallof Press", bodyPart: "Core", equipment: "Cable", category: "core", defaultRestSeconds: 60,
              instructions: "Cable at chest height to your side. Press the handle out and resist rotation; classic anti-rotation drill."),
        .init(name: "Weighted Sit-Up", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 60,
              instructions: "Hold a plate on the chest. Sit up with control; brace before each rep."),
        .init(name: "Mountain Climber", bodyPart: "Core", equipment: "Bodyweight", category: "core", defaultRestSeconds: 30,
              instructions: "From a plank, drive knees alternately toward the chest with quick tempo. Conditioning + core."),

        // MARK: Forearms

        .init(name: "Wrist Curl", bodyPart: "Forearms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Forearms on a bench, palms up. Curl the dumbbells with the wrists only; full ROM."),
        .init(name: "Reverse Wrist Curl", bodyPart: "Forearms", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Forearms on a bench, palms down. Lift the dumbbells with the wrists; targets the extensors."),
        .init(name: "Reverse Curl", bodyPart: "Forearms", equipment: "Barbell", category: "isolation", defaultRestSeconds: 60,
              instructions: "Overhand grip on the bar. Curl with elbows pinned; biases the brachioradialis and forearm extensors."),
        .init(name: "Farmer's Carry", bodyPart: "Forearms", equipment: "Dumbbell", category: "carry", defaultRestSeconds: 90,
              instructions: "Heavy dumbbells in each hand. Walk for distance or time with shoulders packed and core braced."),
        .init(name: "Suitcase Carry", bodyPart: "Forearms", equipment: "Dumbbell", category: "carry", defaultRestSeconds: 90,
              instructions: "Single dumbbell on one side. Walk while resisting the lateral lean; alternate sides."),
        .init(name: "Plate Pinch", bodyPart: "Forearms", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 60,
              instructions: "Pinch two plates together. Hold for time; brutal grip work."),
        .init(name: "Dead Hang", bodyPart: "Forearms", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hang from a bar with full grip. Builds grip endurance and shoulder mobility."),
        .init(name: "Wrist Roller", bodyPart: "Forearms", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hold a bar with a weight tied via rope. Roll the bar to wind the rope up, then unwind."),

        // MARK: Calves

        .init(name: "Calf Raise", bodyPart: "Calves", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Standing on the platform. Rise onto the toes for full plantarflexion; controlled descent into a deep stretch."),
        .init(name: "Seated Calf Raise", bodyPart: "Calves", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Knees under the pad. Rise onto the balls of the feet; biases the soleus."),
        .init(name: "Donkey Calf Raise", bodyPart: "Calves", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Hinge at the hips with a load on the lower back. Rise onto the toes through a deep range."),
        .init(name: "Single-Leg Calf Raise", bodyPart: "Calves", equipment: "Bodyweight", category: "isolation", defaultRestSeconds: 60,
              instructions: "One leg on a step's edge. Drop the heel for a stretch; rise high through full ROM."),
        .init(name: "Smith Machine Calf Raise", bodyPart: "Calves", equipment: "Smith Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Bar across the upper back, balls of feet on a plate. Rise high; pause briefly at the top."),
        .init(name: "Leg Press Calf Raise", bodyPart: "Calves", equipment: "Machine", category: "isolation", defaultRestSeconds: 60,
              instructions: "Balls of the feet on the bottom edge of the platform. Press through the toes for full plantarflexion.")
    ]
}
