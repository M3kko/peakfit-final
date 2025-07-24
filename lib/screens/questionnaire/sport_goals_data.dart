// sport_goals_data.dart

class SportGoals {
  // Backend goal keys for each display goal (updated to match goal_conversions.js)
  static final Map<String, String> goalKeyMappings = {
    // General goals
    'Increase Overall Strength': 'overall_strength',
    'Improve VO2 Max': 'vo2_max',
    'Better Posture & Alignment': 'posture',
    'Achieve Full Splits': 'full_splits',
    'Increase Flexibility': 'flexibility',
    'Boost Vertical Jump': 'vertical_jump',
    'Improve Balance & Stability': 'balance_stability',
    'Faster Recovery Time': 'recovery_time',
    'Build Core Strength': 'core_strength',
    'Improve Coordination': 'coordination',

    // Sport-specific goals - consolidated to match backend conversions
    'Increase Back Strength': 'back_strength',
    'Improve Shoulder Stability': 'shoulder_stability',

    // All smash/serve/shot/overhead power goals map to same backend
    'Increase Smash Power': 'overhead_power',
    'Increase Serve Power': 'overhead_power',
    'Build Shot Power': 'overhead_power',
    'Increase Overhead Strength': 'overhead_power',
    'Build Shoulder Power': 'overhead_power',

    'Improve Lateral Movement': 'lateral_movement',
    'Better Wrist Strength': 'wrist_strength',

    // All jump/vertical goals map to same backend
    'Increase Jump Height': 'vertical_jump',
    'Boost Vertical Jump': 'vertical_jump',
    'Increase Vertical Jump': 'vertical_jump',

    'Improve Extension': 'extension',

    // All rotation goals map to rotational_power
    'Better Rotation Control': 'rotational_power',
    'Increase Rotational Power': 'rotational_power',
    'Improve Core Rotation': 'rotational_power',
    'Increase Rotation Power': 'rotational_power',
    'Improve Rotation Power': 'rotational_power',

    // All upper body strength goals map to same backend
    'Increase Arm Strength': 'upper_body_strength',
    'Build Upper Body Strength': 'upper_body_strength',
    'Build Upper Body Power': 'upper_body_strength',

    // All hip mobility goals map to same backend
    'Better Hip Mobility': 'hip_mobility',
    'Increase Hip Flexibility': 'hip_mobility',
    'Better Hip Flexibility': 'hip_mobility',

    'Improve Sprint Speed': 'sprint_speed',

    // All lateral quickness goals map to same backend
    'Improve Lateral Quickness': 'lateral_quickness',
    'Better Court Speed': 'lateral_quickness',
    'Improve Transition Speed': 'lateral_quickness',

    // All balance goals map to balance_stability
    'Better Balance': 'balance_stability',
    'Better Balance Control': 'balance_stability',
    'Improve Balance & Stability': 'balance_stability',

    // All striking/punching power goals map to same backend
    'Increase Punching Power': 'striking_power',
    'Build Striking Power': 'striking_power',

    'Better Footwork Speed': 'footwork_speed',

    // All reaction time goals map to same backend
    'Improve Reaction Time': 'reaction_time',
    'Faster Reaction Time': 'reaction_time',
    'Better Reaction Time': 'reaction_time',

    'Build Pull-Up Strength': 'pull_up_strength',

    // All core control/strength/stability goals map to core_strength
    'Improve Core Control': 'core_strength',
    'Build Core Strength': 'core_strength',
    'Improve Core Stability': 'core_strength',
    'Better Core Control': 'core_strength',

    'Improve Body Tension': 'body_tension',

    // All flexibility goals map to flexibility
    'Better Flexibility': 'flexibility',
    'Increase Flexibility': 'flexibility',

    // All explosive power goals map to same backend
    'Build Explosive Power': 'explosive_power',
    'Increase Explosive Power': 'explosive_power',

    // All leg strength goals map to same backend
    'Increase Leg Strength': 'leg_strength',
    'Build Leg Strength': 'leg_strength',
    'Build Leg Power': 'leg_strength',

    // All aerobic goals map to aerobic_capacity
    'Improve Aerobic Capacity': 'aerobic_capacity',
    'Build Aerobic Base': 'aerobic_capacity',

    'Better Power-to-Weight': 'power_to_weight',
    'Better Turn Control': 'turn_control',
    'Improve Lunge Power': 'lunge_power',

    // All agility goals map to agility
    'Increase Agility': 'agility',
    'Improve Agility': 'agility',
    'Better Agility': 'agility',

    'Improve Acceleration': 'acceleration',
    'Increase Kick Height': 'kick_height',
    'Improve Grip Strength': 'grip_strength',
    'Increase Jump Distance': 'jump_distance',
    'Better Landing Control': 'landing_control',
    'Build Pulling Power': 'pulling_power',
    'Improve Leg Endurance': 'leg_endurance',
    'Better Edge Control': 'edge_control',
    'Better Stroke Efficiency': 'stroke_efficiency',
    'Build Total Body Strength': 'total_body_strength',
    'Improve Cardiovascular Fitness': 'cardiovascular_fitness',
    'Better Running Economy': 'running_economy',
    'Increase Air Awareness': 'air_awareness',
  };

  // General fitness goals that apply to all sports
  static final List<Map<String, dynamic>> generalGoals = [
    {
      'title': 'Increase Overall Strength',
      'key': 'overall_strength',
      'icon': '💪',
      'description': 'Build functional strength',
    },
    {
      'title': 'Improve VO2 Max',
      'key': 'vo2_max',
      'icon': '🫁',
      'description': 'Enhance oxygen efficiency',
    },
    {
      'title': 'Better Posture & Alignment',
      'key': 'posture',
      'icon': '🧍',
      'description': 'Correct imbalances',
    },
    {
      'title': 'Achieve Full Splits',
      'key': 'full_splits',
      'icon': '🤸',
      'description': 'Maximum hip flexibility',
    },
    {
      'title': 'Increase Flexibility',
      'key': 'flexibility',
      'icon': '🧘',
      'description': 'Better range of motion',
    },
    {
      'title': 'Boost Vertical Jump',
      'key': 'vertical_jump',
      'icon': '🦘',
      'description': 'Explosive lower body power',
    },
    {
      'title': 'Improve Balance & Stability',
      'key': 'balance_stability',
      'icon': '⚖️',
      'description': 'Enhanced proprioception',
    },
    {
      'title': 'Faster Recovery Time',
      'key': 'recovery_time',
      'icon': '♻️',
      'description': 'Optimize rest and repair',
    },
    {
      'title': 'Build Core Strength',
      'key': 'core_strength',
      'icon': '🎯',
      'description': 'Stabilize your center',
    },
    {
      'title': 'Improve Coordination',
      'key': 'coordination',
      'icon': '🎯',
      'description': 'Better mind-muscle connection',
    },
  ];

  // Sport and discipline specific goals - consolidated to match backend mappings
  static final Map<String, Map<String, List<Map<String, dynamic>>>> sportSpecificGoals = {
    'Archery': {
      'Men': [
        {'title': 'Increase Back Strength', 'key': 'back_strength', 'icon': '🏹', 'description': 'Drawing power'},
        {'title': 'Improve Shoulder Stability', 'key': 'shoulder_stability', 'icon': '💪', 'description': 'Steadier hold'},
      ],
      'Women': [
        {'title': 'Increase Back Strength', 'key': 'back_strength', 'icon': '🏹', 'description': 'Drawing power'},
        {'title': 'Improve Shoulder Stability', 'key': 'shoulder_stability', 'icon': '💪', 'description': 'Steadier hold'},
      ],
    },
    'Badminton': {
      'Men': [
        {'title': 'Increase Smash Power', 'key': 'overhead_power', 'icon': '💥', 'description': 'Explosive overhead'},
        {'title': 'Improve Lateral Movement', 'key': 'lateral_movement', 'icon': '↔️', 'description': 'Court coverage'},
        {'title': 'Better Wrist Strength', 'key': 'wrist_strength', 'icon': '🤚', 'description': 'Shot control'},
      ],
      'Women': [
        {'title': 'Increase Smash Power', 'key': 'overhead_power', 'icon': '💥', 'description': 'Explosive overhead'},
        {'title': 'Improve Lateral Movement', 'key': 'lateral_movement', 'icon': '↔️', 'description': 'Court coverage'},
        {'title': 'Better Wrist Strength', 'key': 'wrist_strength', 'icon': '🤚', 'description': 'Shot control'},
      ],
    },
    'Ballet': {
      'Men': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦅', 'description': 'Elevation power'},
        {'title': 'Improve Extension', 'key': 'extension', 'icon': '🦵', 'description': 'Leg flexibility'},
        {'title': 'Better Rotation Control', 'key': 'rotational_power', 'icon': '🌀', 'description': 'Turn stability'},
      ],
      'Women': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦅', 'description': 'Elevation power'},
        {'title': 'Improve Extension', 'key': 'extension', 'icon': '🦵', 'description': 'Leg flexibility'},
        {'title': 'Better Rotation Control', 'key': 'rotational_power', 'icon': '🌀', 'description': 'Turn stability'},
      ],
    },
    'Baseball': {
      'Pitcher/Catcher': [
        {'title': 'Increase Arm Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Throwing power'},
        {'title': 'Better Hip Mobility', 'key': 'hip_mobility', 'icon': '🔄', 'description': 'Rotation range'},
      ],
      'Fielder': [
        {'title': 'Improve Sprint Speed', 'key': 'sprint_speed', 'icon': '🏃', 'description': 'Base running'},
        {'title': 'Increase Rotational Power', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Batting strength'},
      ],
    },
    'Basketball': {
      'Guard': [
        {'title': 'Improve Lateral Quickness', 'key': 'lateral_quickness', 'icon': '↔️', 'description': 'Defensive slides'},
        {'title': 'Increase Vertical Jump', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Finishing at rim'},
      ],
      'Forward/Center': [
        {'title': 'Increase Vertical Jump', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Rebounding power'},
        {'title': 'Build Upper Body Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Post play'},
      ],
    },
    'Bowling': {
      'Men': [
        {'title': 'Improve Core Rotation', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Power generation'},
        {'title': 'Better Balance', 'key': 'balance_stability', 'icon': '⚖️', 'description': 'Consistent approach'},
      ],
      'Women': [
        {'title': 'Improve Core Rotation', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Power generation'},
        {'title': 'Better Balance', 'key': 'balance_stability', 'icon': '⚖️', 'description': 'Consistent approach'},
      ],
    },
    'Boxing': {
      'Men': [
        {'title': 'Increase Punching Power', 'key': 'striking_power', 'icon': '👊', 'description': 'Core to fist transfer'},
        {'title': 'Better Footwork Speed', 'key': 'footwork_speed', 'icon': '👟', 'description': 'Ring movement'},
        {'title': 'Improve Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Defensive reflexes'},
      ],
      'Women': [
        {'title': 'Increase Punching Power', 'key': 'striking_power', 'icon': '👊', 'description': 'Core to fist transfer'},
        {'title': 'Better Footwork Speed', 'key': 'footwork_speed', 'icon': '👟', 'description': 'Ring movement'},
        {'title': 'Improve Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Defensive reflexes'},
      ],
    },
    'Calisthenics': {
      'Men': [
        {'title': 'Build Pull-Up Strength', 'key': 'pull_up_strength', 'icon': '💪', 'description': 'Upper body power'},
        {'title': 'Improve Core Control', 'key': 'core_strength', 'icon': '🎯', 'description': 'Static holds'},
      ],
      'Women': [
        {'title': 'Build Pull-Up Strength', 'key': 'pull_up_strength', 'icon': '💪', 'description': 'Upper body power'},
        {'title': 'Improve Core Control', 'key': 'core_strength', 'icon': '🎯', 'description': 'Static holds'},
      ],
    },
    'Cheerleading': {
      'Base/Spotter': [
        {'title': 'Increase Overhead Strength', 'key': 'overhead_power', 'icon': '🙌', 'description': 'Stunt support'},
      ],
      'Flyer': [
        {'title': 'Improve Body Tension', 'key': 'body_tension', 'icon': '💎', 'description': 'Air control'},
        {'title': 'Better Flexibility', 'key': 'flexibility', 'icon': '🧘', 'description': 'Body positions'},
      ],
      'Base/Tumbler': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🤸', 'description': 'Tumbling power'},
      ],
    },
    'Cycling': {
      'Sprint/Track': [
        {'title': 'Build Explosive Power', 'key': 'explosive_power', 'icon': '⚡', 'description': 'Sprint acceleration'},
        {'title': 'Increase Leg Strength', 'key': 'leg_strength', 'icon': '🦵', 'description': 'Peak power output'},
      ],
      'Endurance/Road': [
        {'title': 'Improve Aerobic Capacity', 'key': 'aerobic_capacity', 'icon': '🫁', 'description': 'Sustained efforts'},
        {'title': 'Better Power-to-Weight', 'key': 'power_to_weight', 'icon': '⛰️', 'description': 'Climbing efficiency'},
      ],
    },
    'Dance': {
      'Men': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Explosive leaps'},
        {'title': 'Improve Flexibility', 'key': 'flexibility', 'icon': '🧘', 'description': 'Movement range'},
        {'title': 'Better Turn Control', 'key': 'turn_control', 'icon': '🌀', 'description': 'Rotation stability'},
      ],
      'Women': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Explosive leaps'},
        {'title': 'Improve Flexibility', 'key': 'flexibility', 'icon': '🧘', 'description': 'Movement range'},
        {'title': 'Better Turn Control', 'key': 'turn_control', 'icon': '🌀', 'description': 'Rotation stability'},
      ],
    },
    'Fencing': {
      'Men': [
        {'title': 'Improve Lunge Power', 'key': 'lunge_power', 'icon': '🤺', 'description': 'Attack distance'},
        {'title': 'Faster Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
      'Women': [
        {'title': 'Improve Lunge Power', 'key': 'lunge_power', 'icon': '🤺', 'description': 'Attack distance'},
        {'title': 'Faster Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
    },
    'Figure Skating': {
      'Singles': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🚀', 'description': 'Rotation height'},
        {'title': 'Better Core Control', 'key': 'core_strength', 'icon': '🌀', 'description': 'Spin stability'},
      ],
      'Pairs': [
        {'title': 'Build Upper Body Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Lift power'},
        {'title': 'Improve Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'Partner work'},
      ],
      'Ice Dance': [
        {'title': 'Increase Hip Flexibility', 'key': 'hip_mobility', 'icon': '🦵', 'description': 'Edge depth'},
        {'title': 'Better Balance Control', 'key': 'balance_stability', 'icon': '⚖️', 'description': 'Precision movements'},
      ],
    },
    'Football': {
      'Skill Position': [
        {'title': 'Improve Sprint Speed', 'key': 'sprint_speed', 'icon': '⚡', 'description': 'Breakaway speed'},
        {'title': 'Increase Agility', 'key': 'agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
      'Line/Power Position': [
        {'title': 'Build Explosive Power', 'key': 'explosive_power', 'icon': '💥', 'description': 'Drive strength'},
        {'title': 'Increase Upper Body Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Blocking power'},
      ],
      'Flag Football': [
        {'title': 'Improve Sprint Speed', 'key': 'sprint_speed', 'icon': '⚡', 'description': 'Open field speed'},
        {'title': 'Better Lateral Movement', 'key': 'lateral_movement', 'icon': '↔️', 'description': 'Defensive coverage'},
      ],
    },
    'Golf': {
      'Men': [
        {'title': 'Increase Rotation Power', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Swing speed'},
        {'title': 'Better Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'Consistent contact'},
        {'title': 'Improve Hip Mobility', 'key': 'hip_mobility', 'icon': '🦵', 'description': 'Full turn'},
      ],
      'Women': [
        {'title': 'Increase Rotation Power', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Swing speed'},
        {'title': 'Better Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'Consistent contact'},
        {'title': 'Improve Hip Mobility', 'key': 'hip_mobility', 'icon': '🦵', 'description': 'Full turn'},
      ],
    },
    'Gymnastics': {
      'Power Events (Rings/Horse)': [
        {'title': 'Build Upper Body Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Static holds'},
      ],
      'All-Around': [
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Tumbling power'},
        {'title': 'Improve Flexibility', 'key': 'flexibility', 'icon': '🧘', 'description': 'Full ROM'},
      ],
      'Balance/Grace Events': [
        {'title': 'Better Balance Control', 'key': 'balance_stability', 'icon': '⚖️', 'description': 'Beam stability'},
        {'title': 'Increase Flexibility', 'key': 'flexibility', 'icon': '🦵', 'description': 'Split leaps'},
      ],
    },
    'Ice Hockey': {
      'Forward/Defense': [
        {'title': 'Improve Acceleration', 'key': 'acceleration', 'icon': '⚡', 'description': 'First steps'},
        {'title': 'Build Shot Power', 'key': 'overhead_power', 'icon': '🏒', 'description': 'Slap shot strength'},
      ],
      'Goaltender': [
        {'title': 'Better Hip Flexibility', 'key': 'hip_mobility', 'icon': '🦋', 'description': 'Butterfly saves'},
        {'title': 'Faster Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Quick saves'},
      ],
    },
    'Martial Arts': {
      'Striking Arts': [
        {'title': 'Increase Kick Height', 'key': 'kick_height', 'icon': '🦵', 'description': 'Hip flexibility'},
        {'title': 'Build Striking Power', 'key': 'striking_power', 'icon': '👊', 'description': 'Impact force'},
      ],
      'Grappling Arts': [
        {'title': 'Improve Grip Strength', 'key': 'grip_strength', 'icon': '🤝', 'description': 'Control power'},
        {'title': 'Better Hip Mobility', 'key': 'hip_mobility', 'icon': '🔄', 'description': 'Ground movement'},
      ],
    },
    'Parkour': {
      'Men': [
        {'title': 'Build Upper Body Power', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Wall climbs'},
        {'title': 'Increase Jump Distance', 'key': 'jump_distance', 'icon': '🦘', 'description': 'Gap clearing'},
        {'title': 'Better Landing Control', 'key': 'landing_control', 'icon': '🦵', 'description': 'Impact absorption'},
      ],
      'Women': [
        {'title': 'Build Upper Body Power', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Wall climbs'},
        {'title': 'Increase Jump Distance', 'key': 'jump_distance', 'icon': '🦘', 'description': 'Gap clearing'},
        {'title': 'Better Landing Control', 'key': 'landing_control', 'icon': '🦵', 'description': 'Impact absorption'},
      ],
    },
    'Rock Climbing': {
      'Men': [
        {'title': 'Increase Grip Strength', 'key': 'grip_strength', 'icon': '🤏', 'description': 'Hold endurance'},
        {'title': 'Better Hip Flexibility', 'key': 'hip_mobility', 'icon': '🦵', 'description': 'High steps'},
      ],
      'Women': [
        {'title': 'Increase Grip Strength', 'key': 'grip_strength', 'icon': '🤏', 'description': 'Hold endurance'},
        {'title': 'Better Hip Flexibility', 'key': 'hip_mobility', 'icon': '🦵', 'description': 'High steps'},
      ],
    },
    'Rowing': {
      'Men': [
        {'title': 'Build Pulling Power', 'key': 'pulling_power', 'icon': '🚣', 'description': 'Stroke strength'},
        {'title': 'Improve Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'Power transfer'},
      ],
      'Women': [
        {'title': 'Build Pulling Power', 'key': 'pulling_power', 'icon': '🚣', 'description': 'Stroke strength'},
        {'title': 'Improve Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'Power transfer'},
      ],
    },
    'Running': {
      'Sprints': [
        {'title': 'Increase Explosive Power', 'key': 'explosive_power', 'icon': '⚡', 'description': 'Acceleration'},
        {'title': 'Build Leg Strength', 'key': 'leg_strength', 'icon': '🦵', 'description': 'Drive force'},
      ],
      'Distance': [
        {'title': 'Improve Aerobic Capacity', 'key': 'aerobic_capacity', 'icon': '🫁', 'description': 'Endurance base'},
        {'title': 'Better Running Economy', 'key': 'running_economy', 'icon': '🏃', 'description': 'Efficiency'},
      ],
    },
    'Skiing': {
      'Technical (Slalom)': [
        {'title': 'Improve Leg Endurance', 'key': 'leg_endurance', 'icon': '🦵', 'description': 'Burn resistance'},
        {'title': 'Better Edge Control', 'key': 'edge_control', 'icon': '🎿', 'description': 'Precision turns'},
      ],
      'Speed (Downhill)': [
        {'title': 'Build Leg Strength', 'key': 'leg_strength', 'icon': '🦵', 'description': 'G-force resistance'},
        {'title': 'Improve Core Stability', 'key': 'core_strength', 'icon': '🎯', 'description': 'High-speed control'},
      ],
    },
    'Snowboarding': {
      'Park/Freestyle': [
        {'title': 'Increase Air Awareness', 'key': 'air_awareness', 'icon': '🚀', 'description': 'Spatial control'},
        {'title': 'Better Balance', 'key': 'balance_stability', 'icon': '⚖️', 'description': 'Rail skills'},
      ],
      'Alpine/Racing': [
        {'title': 'Build Leg Power', 'key': 'leg_strength', 'icon': '🦵', 'description': 'Carving strength'},
      ],
    },
    'Soccer': {
      'Men': [
        {'title': 'Improve Sprint Speed', 'key': 'sprint_speed', 'icon': '⚡', 'description': 'Breakaways'},
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Headers'},
        {'title': 'Better Agility', 'key': 'agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
      'Women': [
        {'title': 'Improve Sprint Speed', 'key': 'sprint_speed', 'icon': '⚡', 'description': 'Breakaways'},
        {'title': 'Increase Jump Height', 'key': 'vertical_jump', 'icon': '🦘', 'description': 'Headers'},
        {'title': 'Better Agility', 'key': 'agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
    },
    'Speed Skating': {
      'Men': [
        {'title': 'Build Leg Power', 'key': 'leg_strength', 'icon': '🦵', 'description': 'Push strength'},
        {'title': 'Better Core Control', 'key': 'core_strength', 'icon': '🎯', 'description': 'Corner stability'},
      ],
      'Women': [
        {'title': 'Build Leg Power', 'key': 'leg_strength', 'icon': '🦵', 'description': 'Push strength'},
        {'title': 'Better Core Control', 'key': 'core_strength', 'icon': '🎯', 'description': 'Corner stability'},
      ],
    },
    'Swimming': {
      'Sprint (50m-100m)': [
        {'title': 'Increase Explosive Power', 'key': 'explosive_power', 'icon': '💥', 'description': 'Start & turns'},
        {'title': 'Build Upper Body Strength', 'key': 'upper_body_strength', 'icon': '💪', 'description': 'Pull power'},
      ],
      'Distance (400m+)': [
        {'title': 'Improve Aerobic Capacity', 'key': 'aerobic_capacity', 'icon': '🫁', 'description': 'Endurance base'},
        {'title': 'Better Stroke Efficiency', 'key': 'stroke_efficiency', 'icon': '🏊', 'description': 'Energy saving'},
      ],
    },
    'Tennis': {
      'Men': [
        {'title': 'Increase Serve Power', 'key': 'overhead_power', 'icon': '🎾', 'description': 'Shoulder strength'},
        {'title': 'Better Court Speed', 'key': 'lateral_quickness', 'icon': '⚡', 'description': 'Coverage'},
        {'title': 'Improve Rotation Power', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Groundstrokes'},
      ],
      'Women': [
        {'title': 'Increase Serve Power', 'key': 'overhead_power', 'icon': '🎾', 'description': 'Shoulder strength'},
        {'title': 'Better Court Speed', 'key': 'lateral_quickness', 'icon': '⚡', 'description': 'Coverage'},
        {'title': 'Improve Rotation Power', 'key': 'rotational_power', 'icon': '🔄', 'description': 'Groundstrokes'},
      ],
    },
    'Triathlon': {
      'Men': [
        {'title': 'Build Aerobic Base', 'key': 'aerobic_capacity', 'icon': '🫁', 'description': 'Multi-sport endurance'},
        {'title': 'Improve Transition Speed', 'key': 'lateral_quickness', 'icon': '🔄', 'description': 'Sport switching'},
      ],
      'Women': [
        {'title': 'Build Aerobic Base', 'key': 'aerobic_capacity', 'icon': '🫁', 'description': 'Multi-sport endurance'},
        {'title': 'Improve Transition Speed', 'key': 'lateral_quickness', 'icon': '🔄', 'description': 'Sport switching'},
      ],
    },
    'Volleyball': {
      'Front Row (Hitter/Blocker)': [
        {'title': 'Increase Vertical Jump', 'key': 'vertical_jump', 'icon': '🏐', 'description': 'Attack height'},
        {'title': 'Build Shoulder Power', 'key': 'overhead_power', 'icon': '💪', 'description': 'Spike strength'},
      ],
      'Back Row (Setter/Libero)': [
        {'title': 'Improve Agility', 'key': 'agility', 'icon': '🔄', 'description': 'Court coverage'},
        {'title': 'Better Reaction Time', 'key': 'reaction_time', 'icon': '⚡', 'description': 'Defensive saves'},
      ],
    },
    'General Fitness': {
      'Men': [
        {'title': 'Build Total Body Strength', 'key': 'total_body_strength', 'icon': '💪', 'description': 'Functional power'},
        {'title': 'Improve Cardiovascular Fitness', 'key': 'cardiovascular_fitness', 'icon': '❤️', 'description': 'Heart health'},
      ],
      'Women': [
        {'title': 'Build Total Body Strength', 'key': 'total_body_strength', 'icon': '💪', 'description': 'Functional power'},
        {'title': 'Improve Cardiovascular Fitness', 'key': 'cardiovascular_fitness', 'icon': '❤️', 'description': 'Heart health'},
      ],
    },
  };

  // Helper method to get goals for a specific sport and discipline
  static List<Map<String, dynamic>> getGoalsForDiscipline(String sport, String discipline) {
    List<Map<String, dynamic>> specificGoals = [];

    // Handle special cases where discipline contains gender info
    if (discipline.contains('Men') || discipline.contains('Women')) {
      String gender = discipline.contains('Men') ? 'Men' : 'Women';
      if (sportSpecificGoals[sport]?[gender] != null) {
        specificGoals = sportSpecificGoals[sport]![gender]!;
      }
    } else {
      // For non-gender specific disciplines (like positions)
      if (sportSpecificGoals[sport]?[discipline] != null) {
        specificGoals = sportSpecificGoals[sport]![discipline]!;
      }
    }

    return specificGoals;
  }

  // Helper method to get backend keys for selected goals
  static List<String> getBackendKeys(List<Map<String, dynamic>> selectedGoals) {
    return selectedGoals.map((goal) => goal['key'] as String).toList();
  }

  // Helper method to convert display title to backend key
  static String? getBackendKey(String displayTitle) {
    return goalKeyMappings[displayTitle];
  }
}