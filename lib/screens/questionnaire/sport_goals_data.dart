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
      'title': 'Increase Bone Density',
      'icon': '🦴',
      'description': 'Stronger skeletal system',
    },
  ];

  // Sport and discipline specific goals
  static final Map<String, Map<String, List<Map<String, dynamic>>>> sportSpecificGoals = {
    'Archery': {
      'Men': [
        {'title': 'Increase Draw Weight to 50lbs', 'icon': '🏹', 'description': 'Build back strength'},
        {'title': 'Hold Steady for 30+ Seconds', 'icon': '⏱️', 'description': 'Improve stability'},
        {'title': 'Reduce Grouping to 3cm at 70m', 'icon': '🎯', 'description': 'Enhance precision'},
      ],
      'Women': [
        {'title': 'Increase Draw Weight to 42lbs', 'icon': '🏹', 'description': 'Build back strength'},
        {'title': 'Hold Steady for 30+ Seconds', 'icon': '⏱️', 'description': 'Improve stability'},
        {'title': 'Reduce Grouping to 3cm at 70m', 'icon': '🎯', 'description': 'Enhance precision'},
      ],
    },
    'Badminton': {
      'Men': [
        {'title': 'Smash Speed 380+ km/h', 'icon': '💥', 'description': 'Explosive power'},
        {'title': 'Court Coverage in 3 Steps', 'icon': '👟', 'description': 'Agility improvement'},
        {'title': 'Rally Endurance 40+ Shots', 'icon': '♻️', 'description': 'Stamina building'},
      ],
      'Women': [
        {'title': 'Smash Speed 350+ km/h', 'icon': '💥', 'description': 'Explosive power'},
        {'title': 'Court Coverage in 3 Steps', 'icon': '👟', 'description': 'Agility improvement'},
        {'title': 'Rally Endurance 40+ Shots', 'icon': '♻️', 'description': 'Stamina building'},
      ],
    },
    'Ballet': {
      'Men': [
        {'title': 'Hold 6+ Pirouettes', 'icon': '🌀', 'description': 'Rotational control'},
        {'title': 'Grand Jeté Split 180°', 'icon': '🦅', 'description': 'Aerial flexibility'},
        {'title': 'Partner Lift Strength', 'icon': '🤝', 'description': 'Upper body power'},
      ],
      'Women': [
        {'title': '32 Fouettés En Pointe', 'icon': '🩰', 'description': 'Endurance & technique'},
        {'title': 'Penché to 180°', 'icon': '🦢', 'description': 'Extension flexibility'},
        {'title': 'Hold Arabesque 60+ Seconds', 'icon': '⏱️', 'description': 'Stability & strength'},
      ],
    },
    'Baseball': {
      'Pitcher/Catcher': [
        {'title': 'Add 5mph to Fastball', 'icon': '⚡', 'description': 'Velocity increase'},
        {'title': 'Pop Time Under 2.0s', 'icon': '⏱️', 'description': 'Quick release'},
        {'title': 'Spin Rate 2400+ RPM', 'icon': '🌀', 'description': 'Better movement'},
      ],
      'Fielder': [
        {'title': '60-yard Dash Under 6.7s', 'icon': '🏃', 'description': 'Sprint speed'},
        {'title': 'Vertical Jump 30+ inches', 'icon': '🦘', 'description': 'Explosive power'},
        {'title': 'Exit Velocity 95+ mph', 'icon': '💪', 'description': 'Hitting power'},
      ],
    },
    'Basketball': {
      'Guard': [
        {'title': 'Sprint Speed Sub-4.5s', 'icon': '⚡', 'description': '40-yard dash'},
        {'title': 'Handle Pressure 85%+', 'icon': '🏀', 'description': 'Ball control'},
        {'title': '3-Point Accuracy 40%+', 'icon': '🎯', 'description': 'Shooting precision'},
      ],
      'Forward/Center': [
        {'title': 'Vertical Jump 35+ inches', 'icon': '🦘', 'description': 'Rebounding power'},
        {'title': 'Bench Press 20+ reps', 'icon': '💪', 'description': 'Upper strength'},
        {'title': 'Post Moves 80%+ Success', 'icon': '🎯', 'description': 'Inside scoring'},
      ],
    },
    'Bowling': {
      'Men': [
        {'title': 'Rev Rate 400+ RPM', 'icon': '🌀', 'description': 'Ball rotation'},
        {'title': 'Spare Conversion 95%+', 'icon': '🎯', 'description': 'Consistency'},
        {'title': 'Ball Speed 17+ mph', 'icon': '⚡', 'description': 'Power delivery'},
      ],
      'Women': [
        {'title': 'Rev Rate 350+ RPM', 'icon': '🌀', 'description': 'Ball rotation'},
        {'title': 'Spare Conversion 95%+', 'icon': '🎯', 'description': 'Consistency'},
        {'title': 'Ball Speed 15+ mph', 'icon': '⚡', 'description': 'Power delivery'},
      ],
    },
    'Boxing': {
      'Men': [
        {'title': 'Punch Force 2500+ Newtons', 'icon': '👊', 'description': 'Impact power'},
        {'title': '180+ Punches/Round', 'icon': '💨', 'description': 'Output volume'},
        {'title': 'Reaction Time <200ms', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
      'Women': [
        {'title': 'Punch Force 2000+ Newtons', 'icon': '👊', 'description': 'Impact power'},
        {'title': '150+ Punches/Round', 'icon': '💨', 'description': 'Output volume'},
        {'title': 'Reaction Time <200ms', 'icon': '⚡', 'description': 'Defensive speed'},
      ],
    },
    'Calisthenics': {
      'Men': [
        {'title': 'Hold Planche 10+ Seconds', 'icon': '🤸', 'description': 'Ultimate strength'},
        {'title': '20+ Muscle-Ups', 'icon': '💪', 'description': 'Power endurance'},
        {'title': 'Human Flag 30+ Seconds', 'icon': '🚩', 'description': 'Core control'},
      ],
      'Women': [
        {'title': 'Hold Front Lever 10+ Seconds', 'icon': '🤸', 'description': 'Core strength'},
        {'title': '10+ Pull-Ups Strict', 'icon': '💪', 'description': 'Upper body'},
        {'title': 'Handstand 60+ Seconds', 'icon': '🙃', 'description': 'Balance control'},
      ],
    },
    'Cheerleading': {
      'Base/Spotter': [
        {'title': 'Overhead Press Bodyweight', 'icon': '💪', 'description': 'Stunt strength'},
        {'title': 'Hold Stunts 30+ Seconds', 'icon': '⏱️', 'description': 'Endurance'},
        {'title': 'Catch from 10ft Heights', 'icon': '🤲', 'description': 'Safety skills'},
      ],
      'Flyer': [
        {'title': 'Single Leg Balance 60s', 'icon': '🦩', 'description': 'Stability'},
        {'title': 'Full Body Tension Hold', 'icon': '💎', 'description': 'Air awareness'},
        {'title': 'Flexibility Score 9+/10', 'icon': '🧘', 'description': 'Range of motion'},
      ],
      'Base/Tumbler': [
        {'title': 'Standing Back Tuck Height', 'icon': '🤸', 'description': 'Explosive power'},
        {'title': 'Round-off Series Speed', 'icon': '⚡', 'description': 'Tumbling velocity'},
        {'title': 'Core Strength 2x Bodyweight', 'icon': '💪', 'description': 'Power base'},
      ],
    },
    'Cycling': {
      'Sprint/Track': [
        {'title': 'Peak Power 2000+ Watts', 'icon': '⚡', 'description': 'Maximum output'},
        {'title': 'Cadence 140+ RPM', 'icon': '🌀', 'description': 'Leg speed'},
        {'title': '200m Time Under 10s', 'icon': '⏱️', 'description': 'Sprint performance'},
      ],
      'Endurance/Road': [
        {'title': 'FTP 5+ W/kg', 'icon': '📈', 'description': 'Sustained power'},
        {'title': 'VO2 Max 70+ ml/kg/min', 'icon': '🫁', 'description': 'Aerobic capacity'},
        {'title': 'Century Ride Under 5hrs', 'icon': '🚴', 'description': 'Endurance marker'},
      ],
    },
    'Dance': {
      'Men': [
        {'title': 'Jump Height 24+ inches', 'icon': '🦘', 'description': 'Explosive leaps'},
        {'title': 'Turn Speed 3+ Rev/Sec', 'icon': '🌀', 'description': 'Rotation control'},
        {'title': 'Flexibility Full Splits', 'icon': '🧘', 'description': 'Range of motion'},
      ],
      'Women': [
        {'title': 'Turn Series 32+ Fouettés', 'icon': '🌀', 'description': 'Endurance turns'},
        {'title': 'Extension 180°+', 'icon': '🦵', 'description': 'Leg flexibility'},
        {'title': 'Jump Series 16+ Beats', 'icon': '🦘', 'description': 'Petit allegro'},
      ],
    },
    'Fencing': {
      'Men': [
        {'title': 'Reaction Time <250ms', 'icon': '⚡', 'description': 'Parry speed'},
        {'title': 'Lunge Distance 2m+', 'icon': '🤺', 'description': 'Attack range'},
        {'title': 'Footwork Agility <7s', 'icon': '👟', 'description': 'Direction changes'},
      ],
      'Women': [
        {'title': 'Reaction Time <250ms', 'icon': '⚡', 'description': 'Parry speed'},
        {'title': 'Lunge Recovery <1s', 'icon': '🤺', 'description': 'Reset speed'},
        {'title': 'Bout Endurance 15min+', 'icon': '⏱️', 'description': 'Match stamina'},
      ],
    },
    'Figure Skating': {
      'Singles': [
        {'title': 'Quad Jump Height 2ft+', 'icon': '🚀', 'description': 'Rotation height'},
        {'title': 'Spin Speed 6 Rev/Sec', 'icon': '🌀', 'description': 'Rotation velocity'},
        {'title': 'Program Stamina 4min+', 'icon': '⏱️', 'description': 'Full performance'},
      ],
      'Pairs': [
        {'title': 'Lift Hold 8+ Seconds', 'icon': '🤝', 'description': 'Overhead strength'},
        {'title': 'Throw Jump Distance', 'icon': '🚀', 'description': 'Launch power'},
        {'title': 'Sync Timing <0.1s', 'icon': '⏱️', 'description': 'Perfect unison'},
      ],
      'Ice Dance': [
        {'title': 'Edge Depth 25°+', 'icon': '⛸️', 'description': 'Blade control'},
        {'title': 'Twizzle Speed 10 Rev', 'icon': '🌀', 'description': 'Travel rotation'},
        {'title': 'Pattern Precision 2cm', 'icon': '🎯', 'description': 'Accuracy'},
      ],
    },
    'Football': {
      'Skill Position': [
        {'title': '40-yard Dash <4.5s', 'icon': '⚡', 'description': 'Sprint speed'},
        {'title': 'Vertical Jump 35+ inches', 'icon': '🦘', 'description': 'Explosive power'},
        {'title': '3-Cone Drill <6.7s', 'icon': '🔄', 'description': 'Agility'},
      ],
      'Line/Power Position': [
        {'title': 'Bench Press 30+ Reps', 'icon': '💪', 'description': '225lb endurance'},
        {'title': 'Squat 2x Bodyweight', 'icon': '🏋️', 'description': 'Leg strength'},
        {'title': '10-yard Split <1.7s', 'icon': '⚡', 'description': 'First step'},
      ],
      'Flag Football': [
        {'title': '40-yard Dash <5.0s', 'icon': '⚡', 'description': 'Sprint speed'},
        {'title': 'Route Precision 90%+', 'icon': '🎯', 'description': 'Accuracy'},
        {'title': 'Flag Pull Success 80%+', 'icon': '🚩', 'description': 'Defensive skills'},
      ],
    },
    'Golf': {
      'Men': [
        {'title': 'Driver Speed 113+ mph', 'icon': '⚡', 'description': 'Club velocity'},
        {'title': 'X-Factor 45°+', 'icon': '🔄', 'description': 'Hip-shoulder separation'},
        {'title': 'Putting Make % 90+ at 6ft', 'icon': '🎯', 'description': 'Short game'},
      ],
      'Women': [
        {'title': 'Driver Speed 95+ mph', 'icon': '⚡', 'description': 'Club velocity'},
        {'title': 'Flexibility Full Backswing', 'icon': '🔄', 'description': 'Range of motion'},
        {'title': 'Approach Accuracy ±3 yards', 'icon': '🎯', 'description': 'Distance control'},
      ],
    },
    'Gymnastics': {
      'Power Events (Rings/Horse)': [
        {'title': 'Iron Cross Hold 5+ Sec', 'icon': '✝️', 'description': 'Static strength'},
        {'title': 'Planche Hold 3+ Sec', 'icon': '🤸', 'description': 'Horizontal hold'},
        {'title': 'Maltese Hold 2+ Sec', 'icon': '💪', 'description': 'Ultimate strength'},
      ],
      'All-Around': [
        {'title': 'Press Handstand Control', 'icon': '🙃', 'description': 'Strength flexibility'},
        {'title': 'Double Layout Height', 'icon': '🚀', 'description': 'Tumbling power'},
        {'title': 'Endurance 6 Events', 'icon': '♻️', 'description': 'Competition stamina'},
      ],
      'Balance/Grace Events': [
        {'title': 'Split Leap 180°+', 'icon': '🦅', 'description': 'Aerial flexibility'},
        {'title': 'Turn Series Control', 'icon': '🌀', 'description': 'Balance precision'},
        {'title': 'Flexibility Oversplits', 'icon': '🧘', 'description': 'Maximum range'},
      ],
    },
    'Ice Hockey': {
      'Forward/Defense': [
        {'title': '10m Sprint <1.8s', 'icon': '⚡', 'description': 'Acceleration'},
        {'title': 'Shot Speed 140+ km/h', 'icon': '🏒', 'description': 'Slap shot power'},
        {'title': 'VO2 Max 60+ ml/kg/min', 'icon': '🫁', 'description': 'Shift endurance'},
      ],
      'Goaltender': [
        {'title': 'Reaction Time <0.3s', 'icon': '⚡', 'description': 'Save reflexes'},
        {'title': 'Butterfly Recovery <1s', 'icon': '🦋', 'description': 'Position reset'},
        {'title': 'Flexibility Full Splits', 'icon': '🧘', 'description': 'Pad coverage'},
      ],
    },
    'Martial Arts': {
      'Striking Arts': [
        {'title': 'Kick Height Head Level', 'icon': '🦵', 'description': 'Flexibility power'},
        {'title': 'Punch Speed <100ms', 'icon': '👊', 'description': 'Strike velocity'},
        {'title': 'Combination Flow 10+', 'icon': '🥊', 'description': 'Fluid sequences'},
      ],
      'Grappling Arts': [
        {'title': 'Grip Strength 55+ kg', 'icon': '🤝', 'description': 'Control power'},
        {'title': 'Bridge Hip Height 2ft', 'icon': '🌉', 'description': 'Escape strength'},
        {'title': 'Submission Rate 70%+', 'icon': '🎯', 'description': 'Technique success'},
      ],
    },
    'Parkour': {
      'Men': [
        {'title': 'Wall Climb 14ft+', 'icon': '🧗', 'description': 'Vertical power'},
        {'title': 'Precision Jump 10ft+', 'icon': '🎯', 'description': 'Accuracy distance'},
        {'title': 'Flow Run 30+ Moves', 'icon': '🏃', 'description': 'Continuous motion'},
      ],
      'Women': [
        {'title': 'Wall Climb 12ft+', 'icon': '🧗', 'description': 'Vertical power'},
        {'title': 'Balance Rail 30+ Sec', 'icon': '⚖️', 'description': 'Stability control'},
        {'title': 'Vault Speed Efficiency', 'icon': '🦘', 'description': 'Obstacle clearing'},
      ],
    },
    'Rock Climbing': {
      'Men': [
        {'title': 'Climb Grade 5.13+', 'icon': '🧗', 'description': 'Technical difficulty'},
        {'title': 'Hang Time 60+ Sec', 'icon': '⏱️', 'description': 'Grip endurance'},
        {'title': 'Campus Board 1-5-9', 'icon': '💪', 'description': 'Power reach'},
      ],
      'Women': [
        {'title': 'Climb Grade 5.12+', 'icon': '🧗', 'description': 'Technical difficulty'},
        {'title': 'Crimp Strength 80% BW', 'icon': '🤏', 'description': 'Finger power'},
        {'title': 'Flexibility High Step', 'icon': '🦵', 'description': 'Reach range'},
      ],
    },
    'Rowing': {
      'Men': [
        {'title': '2K Time <6:00', 'icon': '⏱️', 'description': 'Power endurance'},
        {'title': 'Watts 500+ Peak', 'icon': '⚡', 'description': 'Maximum pull'},
        {'title': 'VO2 Max 70+ ml/kg/min', 'icon': '🫁', 'description': 'Aerobic power'},
      ],
      'Women': [
        {'title': '2K Time <6:50', 'icon': '⏱️', 'description': 'Power endurance'},
        {'title': 'Watts 400+ Peak', 'icon': '⚡', 'description': 'Maximum pull'},
        {'title': 'Split Consistency ±2s', 'icon': '🎯', 'description': 'Pace control'},
      ],
    },
    'Running': {
      'Sprints': [
        {'title': '100m Under 10.5s', 'icon': '⚡', 'description': 'Maximum velocity'},
        {'title': 'Top Speed 12+ m/s', 'icon': '💨', 'description': 'Peak velocity'},
        {'title': 'Ground Contact <0.1s', 'icon': '👟', 'description': 'Efficiency'},
      ],
      'Distance': [
        {'title': 'Marathon <3:00', 'icon': '🏃', 'description': 'Endurance speed'},
        {'title': 'VO2 Max 75+ ml/kg/min', 'icon': '🫁', 'description': 'Aerobic capacity'},
        {'title': 'Fat Oxidation 0.6 g/min', 'icon': '🔥', 'description': 'Fuel efficiency'},
      ],
    },
    'Skiing': {
      'Technical (Slalom)': [
        {'title': 'Edge Angle 60°+', 'icon': '📐', 'description': 'Carving precision'},
        {'title': 'Gate Rhythm Sub-1s', 'icon': '🎿', 'description': 'Turn frequency'},
        {'title': 'Leg Burn Resistance', 'icon': '🦵', 'description': 'Lactic tolerance'},
      ],
      'Speed (Downhill)': [
        {'title': 'Tuck Position 90s+', 'icon': '🎿', 'description': 'Aerodynamic hold'},
        {'title': 'G-Force Tolerance 4g+', 'icon': '🌀', 'description': 'Turn strength'},
        {'title': 'Reaction Time <200ms', 'icon': '⚡', 'description': 'Terrain response'},
      ],
    },
    'Snowboarding': {
      'Park/Freestyle': [
        {'title': '1080° Spin Control', 'icon': '🌀', 'description': 'Rotation mastery'},
        {'title': 'Air Time 2+ Seconds', 'icon': '🚀', 'description': 'Jump height'},
        {'title': 'Rail Balance 50ft+', 'icon': '⚖️', 'description': 'Grind control'},
      ],
      'Alpine/Racing': [
        {'title': 'Carve Angle 70°+', 'icon': '📐', 'description': 'Edge control'},
        {'title': 'G-Force Legs 4g+', 'icon': '🦵', 'description': 'Turn strength'},
        {'title': 'Gate Precision <0.5m', 'icon': '🎯', 'description': 'Line accuracy'},
      ],
    },
    'Soccer': {
      'Men': [
        {'title': 'Sprint Speed 35+ km/h', 'icon': '⚡', 'description': 'Top velocity'},
        {'title': 'VO2 Max 60+ ml/kg/min', 'icon': '🫁', 'description': 'Match endurance'},
        {'title': 'Vertical Jump 60+ cm', 'icon': '🦘', 'description': 'Header power'},
      ],
      'Women': [
        {'title': 'Sprint Speed 30+ km/h', 'icon': '⚡', 'description': 'Top velocity'},
        {'title': 'Agility Test <11s', 'icon': '🔄', 'description': 'Direction change'},
        {'title': 'Kick Power 80+ km/h', 'icon': '🦵', 'description': 'Shot velocity'},
      ],
    },
    'Speed Skating': {
      'Men': [
        {'title': '500m Under 34s', 'icon': '⏱️', 'description': 'Sprint time'},
        {'title': 'Corner Speed 50+ km/h', 'icon': '🔄', 'description': 'Technical velocity'},
        {'title': 'Push Power 1500+ Watts', 'icon': '⚡', 'description': 'Leg drive'},
      ],
      'Women': [
        {'title': '500m Under 37s', 'icon': '⏱️', 'description': 'Sprint time'},
        {'title': 'Crossover Efficiency 95%+', 'icon': '❌', 'description': 'Technical skill'},
        {'title': 'Lactate Threshold 4+ W/kg', 'icon': '🔥', 'description': 'Endurance power'},
      ],
    },
    'Swimming': {
      'Sprint (50m-100m)': [
        {'title': 'Stroke Rate 60+ SPM', 'icon': '💨', 'description': 'Turnover speed'},
        {'title': 'Underwater Kick 2.5 m/s', 'icon': '🐬', 'description': 'Dolphin velocity'},
        {'title': 'Start Reaction <0.6s', 'icon': '⚡', 'description': 'Block speed'},
      ],
      'Distance (400m+)': [
        {'title': 'Stroke Efficiency 2.5m+', 'icon': '🎯', 'description': 'Distance per stroke'},
        {'title': 'Threshold Pace 1:20/100m', 'icon': '⏱️', 'description': 'Sustained speed'},
        {'title': 'VO2 Max 65+ ml/kg/min', 'icon': '🫁', 'description': 'Aerobic power'},
      ],
    },
    'Tennis': {
      'Men': [
        {'title': 'Serve Speed 200+ km/h', 'icon': '🎾', 'description': 'First serve power'},
        {'title': 'Sprint to Net <2s', 'icon': '⚡', 'description': 'Court coverage'},
        {'title': 'Rally Endurance 30+ Shots', 'icon': '♻️', 'description': 'Point stamina'},
      ],
      'Women': [
        {'title': 'Serve Speed 180+ km/h', 'icon': '🎾', 'description': 'First serve power'},
        {'title': 'Split Step Height 20cm+', 'icon': '🦘', 'description': 'Ready position'},
        {'title': 'Groundstroke 120+ km/h', 'icon': '💪', 'description': 'Baseline power'},
      ],
    },
    'Triathlon': {
      'Men': [
        {'title': 'Swim Pace <1:20/100m', 'icon': '🏊', 'description': 'Open water speed'},
        {'title': 'Bike FTP 4.5+ W/kg', 'icon': '🚴', 'description': 'Cycling power'},
        {'title': 'Run Off Bike <3:30/km', 'icon': '🏃', 'description': 'Transition speed'},
      ],
      'Women': [
        {'title': 'Swim Efficiency 65+ SWOLF', 'icon': '🏊', 'description': 'Stroke economy'},
        {'title': 'Bike Cadence 90+ RPM', 'icon': '🚴', 'description': 'Pedal efficiency'},
        {'title': 'Run Economy 200 ml/kg/km', 'icon': '🏃', 'description': 'Efficiency'},
      ],
    },
    'Volleyball': {
      'Front Row (Hitter/Blocker)': [
        {'title': 'Spike Touch 11ft+', 'icon': '🏐', 'description': 'Attack height'},
        {'title': 'Block Touch 10.5ft+', 'icon': '🤚', 'description': 'Net defense'},
        {'title': 'Approach Jump 32+ in', 'icon': '🦘', 'description': 'Vertical power'},
      ],
      'Back Row (Setter/Libero)': [
        {'title': 'Set Accuracy 90%+', 'icon': '🎯', 'description': 'Ball placement'},
        {'title': 'Dig Success 80%+', 'icon': '🛡️', 'description': 'Defense rate'},
        {'title': 'Agility T-Test <9s', 'icon': '🔄', 'description': 'Court movement'},
      ],
    },
    'General Fitness': {
      'Men': [
        {'title': 'Deadlift 2x Bodyweight', 'icon': '🏋️', 'description': 'Total body strength'},
        {'title': 'Pull-ups 20+ Reps', 'icon': '💪', 'description': 'Upper body power'},
        {'title': '5K Run Under 20min', 'icon': '🏃', 'description': 'Cardio fitness'},
      ],
      'Women': [
        {'title': 'Deadlift 1.5x Bodyweight', 'icon': '🏋️', 'description': 'Total body strength'},
        {'title': 'Push-ups 30+ Reps', 'icon': '💪', 'description': 'Upper body endurance'},
        {'title': '5K Run Under 25min', 'icon': '🏃', 'description': 'Cardio fitness'},
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