// sport_goals_data.dart

class SportGoals {
  // General fitness goals that apply to all sports
  static final List<Map<String, dynamic>> generalGoals = [
    {
      'title': 'Increase Overall Strength',
      'icon': '💪',
      'description': 'Build functional strength',
    },
    {
      'title': 'Improve VO2 Max',
      'icon': '🫁',
      'description': 'Enhance oxygen efficiency',
    },
    {
      'title': 'Better Posture & Alignment',
      'icon': '🧍',
      'description': 'Correct imbalances',
    },
    {
      'title': 'Achieve Full Splits',
      'icon': '🤸',
      'description': 'Maximum hip flexibility',
    },
    {
      'title': 'Increase Flexibility',
      'icon': '🧘',
      'description': 'Better range of motion',
    },
    {
      'title': 'Boost Vertical Jump',
      'icon': '🦘',
      'description': 'Explosive lower body power',
    },
    {
      'title': 'Improve Balance & Stability',
      'icon': '⚖️',
      'description': 'Enhanced proprioception',
    },
    {
      'title': 'Faster Recovery Time',
      'icon': '♻️',
      'description': 'Optimize rest and repair',
    },
    {
      'title': 'Build Core Strength',
      'icon': '🎯',
      'description': 'Stabilize your center',
    },
    {
      'title': 'Improve Coordination',
      'icon': '🎯',
      'description': 'Better mind-muscle connection',
    },
  ];

  // Sport and discipline specific goals
  static final Map<String, Map<String, List<Map<String, dynamic>>>> sportSpecificGoals = {
    'Archery': {
      'Men': [
        {'title': 'Increase Back Strength', 'icon': '🏹', 'description': 'Drawing power'},
        {'title': 'Improve Shoulder Stability', 'icon': '💪', 'description': 'Steadier hold'},
      ],
      'Women': [
        {'title': 'Increase Back Strength', 'icon': '🏹', 'description': 'Drawing power'},
        {'title': 'Improve Shoulder Stability', 'icon': '💪', 'description': 'Steadier hold'},
      ],
    },
    'Badminton': {
      'Men': [
        {'title': 'Increase Smash Power', 'icon': '💥', 'description': 'Explosive overhead'},
        {'title': 'Improve Lateral Movement', 'icon': '↔️', 'description': 'Court coverage'},
        {'title': 'Better Wrist Strength', 'icon': '🤚', 'description': 'Shot control'},
      ],
      'Women': [
        {'title': 'Increase Smash Power', 'icon': '💥', 'description': 'Explosive overhead'},
        {'title': 'Improve Lateral Movement', 'icon': '↔️', 'description': 'Court coverage'},
        {'title': 'Better Wrist Strength', 'icon': '🤚', 'description': 'Shot control'},
      ],
    },
    'Ballet': {
      'Men': [
        {'title': 'Increase Jump Height', 'icon': '🦅', 'description': 'Elevation power'},
        {'title': 'Improve Extension', 'icon': '🦵', 'description': 'Leg flexibility'},
        {'title': 'Better Rotation Control', 'icon': '🌀', 'description': 'Turn stability'},
      ],
      'Women': [
        {'title': 'Increase Jump Height', 'icon': '🦅', 'description': 'Elevation power'},
        {'title': 'Improve Extension', 'icon': '🦵', 'description': 'Leg flexibility'},
        {'title': 'Better Rotation Control', 'icon': '🌀', 'description': 'Turn stability'},
      ],
    },
    'Baseball': {
      'Pitcher/Catcher': [
        {'title': 'Increase Arm Strength', 'icon': '💪', 'description': 'Throwing power'},
        {'title': 'Better Hip Mobility', 'icon': '🔄', 'description': 'Rotation range'},
      ],
      'Fielder': [
        {'title': 'Improve Sprint Speed', 'icon': '🏃', 'description': 'Base running'},
        {'title': 'Increase Rotational Power', 'icon': '🔄', 'description': 'Batting strength'},
      ],
    },
    'Basketball': {
      'Guard': [
        {'title': 'Improve Lateral Quickness', 'icon': '↔️', 'description': 'Defensive slides'},
        {'title': 'Increase Vertical Jump', 'icon': '🦘', 'description': 'Finishing at rim'},
      ],
      'Forward/Center': [
        {'title': 'Increase Vertical Jump', 'icon': '🦘', 'description': 'Rebounding power'},
        {'title': 'Build Upper Body Strength', 'icon': '💪', 'description': 'Post play'},
      ],
    },
    'Bowling': {
      'Men': [
        {'title': 'Improve Core Rotation', 'icon': '🔄', 'description': 'Power generation'},
        {'title': 'Better Balance', 'icon': '⚖️', 'description': 'Consistent approach'},
      ],
      'Women': [
        {'title': 'Improve Core Rotation', 'icon': '🔄', 'description': 'Power generation'},
        {'title': 'Better Balance', 'icon': '⚖️', 'description': 'Consistent approach'},
      ],
    },
    'Boxing': {
      'Men': [
        {'title': 'Increase Punching Power', 'icon': '👊', 'description': 'Core to fist transfer'},
        {'title': 'Better Footwork Speed', 'icon': '👟', 'description': 'Ring movement'},
        {'title': 'Improve Reaction Time', 'icon': '⚡', 'description': 'Defensive reflexes'},
      ],
      'Women': [
        {'title': 'Increase Punching Power', 'icon': '👊', 'description': 'Core to fist transfer'},
        {'title': 'Better Footwork Speed', 'icon': '👟', 'description': 'Ring movement'},
        {'title': 'Improve Reaction Time', 'icon': '⚡', 'description': 'Defensive reflexes'},
      ],
    },
    'Calisthenics': {
      'Men': [
        {'title': 'Build Pull-Up Strength', 'icon': '💪', 'description': 'Upper body power'},
        {'title': 'Improve Core Control', 'icon': '🎯', 'description': 'Static holds'},
      ],
      'Women': [
        {'title': 'Build Pull-Up Strength', 'icon': '💪', 'description': 'Upper body power'},
        {'title': 'Improve Core Control', 'icon': '🎯', 'description': 'Static holds'},
      ],
    },
    'Cheerleading': {
      'Base/Spotter': [
        {'title': 'Increase Overhead Strength', 'icon': '🙌', 'description': 'Stunt support'},
      ],
      'Flyer': [
        {'title': 'Improve Body Tension', 'icon': '💎', 'description': 'Air control'},
        {'title': 'Better Flexibility', 'icon': '🧘', 'description': 'Body positions'},
      ],
      'Base/Tumbler': [
        {'title': 'Increase Jump Height', 'icon': '🤸', 'description': 'Tumbling power'},
      ],
    },
    'Cycling': {
      'Sprint/Track': [
        {'title': 'Build Explosive Power', 'icon': '⚡', 'description': 'Sprint acceleration'},
        {'title': 'Increase Leg Strength', 'icon': '🦵', 'description': 'Peak power output'},
      ],
      'Endurance/Road': [
        {'title': 'Improve Aerobic Capacity', 'icon': '🫁', 'description': 'Sustained efforts'},
        {'title': 'Better Power-to-Weight', 'icon': '⛰️', 'description': 'Climbing efficiency'},
      ],
    },
    'Dance': {
      'Men': [
        {'title': 'Increase Jump Height', 'icon': '🦘', 'description': 'Explosive leaps'},
        {'title': 'Improve Flexibility', 'icon': '🧘', 'description': 'Movement range'},
        {'title': 'Better Turn Control', 'icon': '🌀', 'description': 'Rotation stability'},
      ],
      'Women': [
        {'title': 'Increase Jump Height', 'icon': '🦘', 'description': 'Explosive leaps'},
        {'title': 'Improve Flexibility', 'icon': '🧘', 'description': 'Movement range'},
        {'title': 'Better Turn Control', 'icon': '🌀', 'description': 'Rotation stability'},
      ],
    },
    'Fencing': {
      'Men': [
        {'title': 'Improve Lunge Power', 'icon': '🤺', 'description': 'Attack distance'},
        {'title': 'Faster Reaction Time', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
      'Women': [
        {'title': 'Improve Lunge Power', 'icon': '🤺', 'description': 'Attack distance'},
        {'title': 'Faster Reaction Time', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
    },
    'Figure Skating': {
      'Singles': [
        {'title': 'Increase Jump Height', 'icon': '🚀', 'description': 'Rotation height'},
        {'title': 'Better Core Control', 'icon': '🌀', 'description': 'Spin stability'},
      ],
      'Pairs': [
        {'title': 'Build Upper Body Strength', 'icon': '💪', 'description': 'Lift power'},
        {'title': 'Improve Core Stability', 'icon': '🎯', 'description': 'Partner work'},
      ],
      'Ice Dance': [
        {'title': 'Increase Hip Flexibility', 'icon': '🦵', 'description': 'Edge depth'},
        {'title': 'Better Balance Control', 'icon': '⚖️', 'description': 'Precision movements'},
      ],
    },
    'Football': {
      'Skill Position': [
        {'title': 'Improve Sprint Speed', 'icon': '⚡', 'description': 'Breakaway speed'},
        {'title': 'Increase Agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
      'Line/Power Position': [
        {'title': 'Build Explosive Power', 'icon': '💥', 'description': 'Drive strength'},
        {'title': 'Increase Upper Body Strength', 'icon': '💪', 'description': 'Blocking power'},
      ],
      'Flag Football': [
        {'title': 'Improve Sprint Speed', 'icon': '⚡', 'description': 'Open field speed'},
        {'title': 'Better Lateral Movement', 'icon': '↔️', 'description': 'Defensive coverage'},
      ],
    },
    'Golf': {
      'Men': [
        {'title': 'Increase Rotation Power', 'icon': '🔄', 'description': 'Swing speed'},
        {'title': 'Better Core Stability', 'icon': '🎯', 'description': 'Consistent contact'},
        {'title': 'Improve Hip Mobility', 'icon': '🦵', 'description': 'Full turn'},
      ],
      'Women': [
        {'title': 'Increase Rotation Power', 'icon': '🔄', 'description': 'Swing speed'},
        {'title': 'Better Core Stability', 'icon': '🎯', 'description': 'Consistent contact'},
        {'title': 'Improve Hip Mobility', 'icon': '🦵', 'description': 'Full turn'},
      ],
    },
    'Gymnastics': {
      'Power Events (Rings/Horse)': [
        {'title': 'Build Upper Body Strength', 'icon': '💪', 'description': 'Static holds'},
      ],
      'All-Around': [
        {'title': 'Increase Jump Height', 'icon': '🦘', 'description': 'Tumbling power'},
        {'title': 'Improve Flexibility', 'icon': '🧘', 'description': 'Full ROM'},
      ],
      'Balance/Grace Events': [
        {'title': 'Better Balance Control', 'icon': '⚖️', 'description': 'Beam stability'},
        {'title': 'Increase Flexibility', 'icon': '🦵', 'description': 'Split leaps'},
      ],
    },
    'Ice Hockey': {
      'Forward/Defense': [
        {'title': 'Improve Acceleration', 'icon': '⚡', 'description': 'First steps'},
        {'title': 'Build Shot Power', 'icon': '🏒', 'description': 'Slap shot strength'},
      ],
      'Goaltender': [
        {'title': 'Better Hip Flexibility', 'icon': '🦋', 'description': 'Butterfly saves'},
        {'title': 'Faster Reaction Time', 'icon': '⚡', 'description': 'Quick saves'},
      ],
    },
    'Martial Arts': {
      'Striking Arts': [
        {'title': 'Increase Kick Height', 'icon': '🦵', 'description': 'Hip flexibility'},
        {'title': 'Build Striking Power', 'icon': '👊', 'description': 'Impact force'},
      ],
      'Grappling Arts': [
        {'title': 'Improve Grip Strength', 'icon': '🤝', 'description': 'Control power'},
        {'title': 'Better Hip Mobility', 'icon': '🔄', 'description': 'Ground movement'},
      ],
    },
    'Parkour': {
      'Men': [
        {'title': 'Build Upper Body Power', 'icon': '💪', 'description': 'Wall climbs'},
        {'title': 'Increase Jump Distance', 'icon': '🦘', 'description': 'Gap clearing'},
        {'title': 'Better Landing Control', 'icon': '🦵', 'description': 'Impact absorption'},
      ],
      'Women': [
        {'title': 'Build Upper Body Power', 'icon': '💪', 'description': 'Wall climbs'},
        {'title': 'Increase Jump Distance', 'icon': '🦘', 'description': 'Gap clearing'},
        {'title': 'Better Landing Control', 'icon': '🦵', 'description': 'Impact absorption'},
      ],
    },
    'Rock Climbing': {
      'Men': [
        {'title': 'Increase Grip Strength', 'icon': '🤏', 'description': 'Hold endurance'},
        {'title': 'Better Hip Flexibility', 'icon': '🦵', 'description': 'High steps'},
      ],
      'Women': [
        {'title': 'Increase Grip Strength', 'icon': '🤏', 'description': 'Hold endurance'},
        {'title': 'Better Hip Flexibility', 'icon': '🦵', 'description': 'High steps'},
      ],
    },
    'Rowing': {
      'Men': [
        {'title': 'Build Pulling Power', 'icon': '🚣', 'description': 'Stroke strength'},
        {'title': 'Improve Core Stability', 'icon': '🎯', 'description': 'Power transfer'},
      ],
      'Women': [
        {'title': 'Build Pulling Power', 'icon': '🚣', 'description': 'Stroke strength'},
        {'title': 'Improve Core Stability', 'icon': '🎯', 'description': 'Power transfer'},
      ],
    },
    'Running': {
      'Sprints': [
        {'title': 'Increase Explosive Power', 'icon': '⚡', 'description': 'Acceleration'},
        {'title': 'Build Leg Strength', 'icon': '🦵', 'description': 'Drive force'},
      ],
      'Distance': [
        {'title': 'Improve Aerobic Capacity', 'icon': '🫁', 'description': 'Endurance base'},
        {'title': 'Better Running Economy', 'icon': '🏃', 'description': 'Efficiency'},
      ],
    },
    'Skiing': {
      'Technical (Slalom)': [
        {'title': 'Improve Leg Endurance', 'icon': '🦵', 'description': 'Burn resistance'},
        {'title': 'Better Edge Control', 'icon': '🎿', 'description': 'Precision turns'},
      ],
      'Speed (Downhill)': [
        {'title': 'Build Leg Strength', 'icon': '🦵', 'description': 'G-force resistance'},
        {'title': 'Improve Core Stability', 'icon': '🎯', 'description': 'High-speed control'},
      ],
    },
    'Snowboarding': {
      'Park/Freestyle': [
        {'title': 'Increase Air Awareness', 'icon': '🚀', 'description': 'Spatial control'},
        {'title': 'Better Balance', 'icon': '⚖️', 'description': 'Rail skills'},
      ],
      'Alpine/Racing': [
        {'title': 'Build Leg Power', 'icon': '🦵', 'description': 'Carving strength'},
      ],
    },
    'Soccer': {
      'Men': [
        {'title': 'Improve Sprint Speed', 'icon': '⚡', 'description': 'Breakaways'},
        {'title': 'Increase Jump Height', 'icon': '🦘', 'description': 'Headers'},
        {'title': 'Better Agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
      'Women': [
        {'title': 'Improve Sprint Speed', 'icon': '⚡', 'description': 'Breakaways'},
        {'title': 'Increase Jump Height', 'icon': '🦘', 'description': 'Headers'},
        {'title': 'Better Agility', 'icon': '🔄', 'description': 'Direction changes'},
      ],
    },
    'Speed Skating': {
      'Men': [
        {'title': 'Build Leg Power', 'icon': '🦵', 'description': 'Push strength'},
        {'title': 'Better Core Control', 'icon': '🎯', 'description': 'Corner stability'},
      ],
      'Women': [
        {'title': 'Build Leg Power', 'icon': '🦵', 'description': 'Push strength'},
        {'title': 'Better Core Control', 'icon': '🎯', 'description': 'Corner stability'},
      ],
    },
    'Swimming': {
      'Sprint (50m-100m)': [
        {'title': 'Increase Explosive Power', 'icon': '💥', 'description': 'Start & turns'},
        {'title': 'Build Upper Body Strength', 'icon': '💪', 'description': 'Pull power'},
      ],
      'Distance (400m+)': [
        {'title': 'Improve Aerobic Capacity', 'icon': '🫁', 'description': 'Endurance base'},
        {'title': 'Better Stroke Efficiency', 'icon': '🏊', 'description': 'Energy saving'},
      ],
    },
    'Tennis': {
      'Men': [
        {'title': 'Increase Serve Power', 'icon': '🎾', 'description': 'Shoulder strength'},
        {'title': 'Better Court Speed', 'icon': '⚡', 'description': 'Coverage'},
        {'title': 'Improve Rotation Power', 'icon': '🔄', 'description': 'Groundstrokes'},
      ],
      'Women': [
        {'title': 'Increase Serve Power', 'icon': '🎾', 'description': 'Shoulder strength'},
        {'title': 'Better Court Speed', 'icon': '⚡', 'description': 'Coverage'},
        {'title': 'Improve Rotation Power', 'icon': '🔄', 'description': 'Groundstrokes'},
      ],
    },
    'Triathlon': {
      'Men': [
        {'title': 'Build Aerobic Base', 'icon': '🫁', 'description': 'Multi-sport endurance'},
        {'title': 'Improve Transition Speed', 'icon': '🔄', 'description': 'Sport switching'},
      ],
      'Women': [
        {'title': 'Build Aerobic Base', 'icon': '🫁', 'description': 'Multi-sport endurance'},
        {'title': 'Improve Transition Speed', 'icon': '🔄', 'description': 'Sport switching'},
      ],
    },
    'Volleyball': {
      'Front Row (Hitter/Blocker)': [
        {'title': 'Increase Vertical Jump', 'icon': '🏐', 'description': 'Attack height'},
        {'title': 'Build Shoulder Power', 'icon': '💪', 'description': 'Spike strength'},
      ],
      'Back Row (Setter/Libero)': [
        {'title': 'Improve Agility', 'icon': '🔄', 'description': 'Court coverage'},
        {'title': 'Better Reaction Time', 'icon': '⚡', 'description': 'Defensive saves'},
      ],
    },
    'General Fitness': {
      'Men': [
        {'title': 'Build Total Body Strength', 'icon': '💪', 'description': 'Functional power'},
        {'title': 'Improve Cardiovascular Fitness', 'icon': '❤️', 'description': 'Heart health'},
      ],
      'Women': [
        {'title': 'Build Total Body Strength', 'icon': '💪', 'description': 'Functional power'},
        {'title': 'Improve Cardiovascular Fitness', 'icon': '❤️', 'description': 'Heart health'},
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
}