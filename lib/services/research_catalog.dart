import '../models/learning_enums.dart';

enum ImplementationStatus {
  implemented,
  experimental,
  contextual,
  instrumentationOnly,
  researchOnly,
  notImplemented;

  String get label => switch (this) {
        ImplementationStatus.implemented => 'Implemented',
        ImplementationStatus.experimental => 'Experimental',
        ImplementationStatus.contextual => 'Contextual',
        ImplementationStatus.instrumentationOnly => 'Instrumentation Only',
        ImplementationStatus.researchOnly => 'Research Only',
        ImplementationStatus.notImplemented => 'Not Implemented',
      };
}

enum SafetyClassification {
  safeSoftware,
  contextual,
  sensorRequired,
  researchInstrumentation,
  medicalResearch,
  pharmacological,
  invasiveOrHighRisk;

  String get label => switch (this) {
        SafetyClassification.safeSoftware => 'Safe Software',
        SafetyClassification.contextual => 'Contextual Observation',
        SafetyClassification.sensorRequired => 'Sensor Required',
        SafetyClassification.researchInstrumentation => 'Research Instrumentation',
        SafetyClassification.medicalResearch => 'Medical Research (Non-Clinical)',
        SafetyClassification.pharmacological => 'Pharmacological (Research Only)',
        SafetyClassification.invasiveOrHighRisk => 'Invasive / High Risk',
      };

  bool get isSafeForConsumerSoftware =>
      this == SafetyClassification.safeSoftware ||
      this == SafetyClassification.contextual;
}

/// Typedef alias for SafetyClassification.
typedef SafetyClass = SafetyClassification;

/// Typedef alias for ResearchEntry.
typedef ResearchCatalogItem = ResearchEntry;

class ResearchEntry {
  final String id;
  final String name;
  final int tier;
  final String category;
  final String description;
  final int evidenceLevel;
  final ImplementationStatus implementationStatus;
  final SafetyClassification safetyLevel;
  final List<ConceptType> supportedConceptTypes;
  final List<TestType> supportedTestTypes;
  final List<String> aliases;

  const ResearchEntry({
    required this.id,
    required this.name,
    required this.tier,
    required this.category,
    required this.description,
    required this.evidenceLevel,
    required this.implementationStatus,
    required this.safetyLevel,
    this.supportedConceptTypes = const [ConceptType.definition, ConceptType.procedure, ConceptType.conceptualModel],
    this.supportedTestTypes = const [TestType.freeRecall, TestType.cuedRecall],
    this.aliases = const [],
  });
}

class ResearchCatalog {
  static final Map<String, ResearchEntry> _registry = {};
  static final Map<String, String> _aliasMap = {};
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    for (final e in _allEntries) {
      _registry[e.id] = e;
      _aliasMap[e.id.toLowerCase()] = e.id;
      for (final a in e.aliases) {
        _aliasMap[a.toLowerCase()] = e.id;
      }
    }
    _initialized = true;
  }

  static List<ResearchEntry> getAll() {
    ensureInitialized();
    return _registry.values.toList();
  }

  static ResearchEntry? getById(String id) {
    ensureInitialized();
    final canonicalId = _aliasMap[id.toLowerCase()] ?? id;
    return _registry[canonicalId];
  }

  static List<ResearchEntry> getByTier(int tier) {
    ensureInitialized();
    return _registry.values.where((e) => e.tier == tier).toList();
  }

  static List<ResearchEntry> getImplemented() {
    ensureInitialized();
    return _registry.values
        .where((e) => e.implementationStatus == ImplementationStatus.implemented)
        .toList();
  }

  static List<ResearchEntry> search(String query) {
    ensureInitialized();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAll();
    return _registry.values.where((e) {
      return e.id.toLowerCase().contains(q) ||
          e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();
  }

  static const List<ResearchEntry> _allEntries = [
    // Tier 1
    ResearchEntry(id: 'free_retrieval', name: 'Free Retrieval', tier: 1, category: 'Retrieval', description: 'Unconstrained active recall without cues.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['free_recall', 'blurt']),
    ResearchEntry(id: 'confidence_calibration', name: 'Confidence Calibration', tier: 1, category: 'Metacognition', description: 'Pre-attempt probability judgments vs actual performance.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['metacognitive_calibration', 'brier_calibration', 'calibration_trajectory']),
    ResearchEntry(id: 'error_classification', name: 'Error Classification', tier: 1, category: 'Metacognition', description: 'Taxonomy grouping into conceptual, procedural, retrieval, attention.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['error_taxonomy', 'error_diagnosis']),
    ResearchEntry(id: 'failure_triggered_strategy_switching', name: 'Failure-Triggered Strategy Switching', tier: 1, category: 'Intervention Engine', description: 'Dynamic strategy shift on persistent errors.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['adaptive_strategy_switching']),
    ResearchEntry(id: 'individual_learning_curves', name: 'Individual Learning Curves', tier: 1, category: 'Analytics', description: 'Empirical acquisition and retention curves without single scores.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['first_principles_learning_curve_modeling', 'learning_curves']),
    ResearchEntry(id: 'transfer_measurement', name: 'Transfer Measurement', tier: 1, category: 'Measurement', description: 'Testing knowledge application in structurally distant domains.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['analogical_transfer_measurement']),
    ResearchEntry(id: 'lector', name: 'LECTOR Framework', tier: 1, category: 'Structure', description: 'Learning Engine for Calibration, Testing, Outcomes, and Retrieval.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['lector_framework']),
    ResearchEntry(id: 'warmup_calibration', name: 'Brain-Inspired Warm-Up Calibration', tier: 1, category: 'Structure', description: 'Pre-session warm-up probing readiness and calibration.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['session_warmup', 'brain_inspired_warmup_calibration']),
    ResearchEntry(id: 'faded_worked_examples', name: 'Faded Worked Examples', tier: 1, category: 'Instruction', description: 'Full solution -> faded steps -> independent execution.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['worked_examples_and_fading']),
    ResearchEntry(id: 'prequestioning', name: 'Prequestioning & Pretesting', tier: 1, category: 'Structure', description: 'Predicting solutions prior to formal exposure.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['pretesting', 'curiosity_priming']),
    ResearchEntry(id: 'schema_induction_contrasting_cases', name: 'Schema Induction via Contrasting Cases', tier: 1, category: 'Structure', description: 'Side-by-side contrasting examples differing by a single rule.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['contrasting_cases', 'contrastive_retrieval']),
    ResearchEntry(id: 'metacognitive_prompts', name: 'Metacognitive Prompts', tier: 1, category: 'Metacognition', description: 'Structured reflection queries during debrief.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['metacognitive_reflection']),
    ResearchEntry(id: 'net_friction_rule', name: 'Net Friction Rule', tier: 1, category: 'Policy', description: 'Intervention yield = (Delayed Benefit) - (Time Cost + Cognitive Friction).', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['friction_utility_model']),
    ResearchEntry(id: 'metacognitive_laziness_countermeasures', name: 'Metacognitive Laziness Countermeasures', tier: 1, category: 'Metacognition', description: 'Friction prompts requiring retrieval commitment.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['anti_laziness_guards']),
    // Tier 2
    ResearchEntry(id: 'meaningful_interleaving', name: 'Meaningful Interleaving', tier: 2, category: 'Scheduling', description: 'Interleaving confusable concepts and competing algorithms.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['interleaving', 'contrastive_interleaving']),
    ResearchEntry(id: 'hyper_correction_effect', name: 'Hyper-Correction Effect', tier: 2, category: 'Feedback', description: 'Prominent corrective explanation on high-confidence errors.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['high_confidence_error_correction']),
    ResearchEntry(id: 'dopamine_rpe', name: 'Reward Prediction Error Mechanics', tier: 2, category: 'Motivation', description: 'Behavioral framing of surprising feedback and resolved uncertainty.', evidenceLevel: 4, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.safeSoftware, aliases: ['reward_prediction_error']),
    ResearchEntry(id: 'implementation_intentions', name: 'Implementation Intentions', tier: 2, category: 'Self-Regulation', description: 'Lightweight "WHEN [condition] THEN I WILL [retrieval]" plans.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['habit_intentions', 'if_then_plans']),
    ResearchEntry(id: 'adaptive_session_length', name: 'Adaptive Session Length', tier: 2, category: 'Structure', description: 'Optimizing session length per user by tracking performance-per-minute.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware),
    ResearchEntry(id: 'concept_type_matching', name: 'Intervention-by-Concept Matching', tier: 2, category: 'Policy', description: 'Matching pedagogical interventions according to target type.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['intervention_concept_matching']),

    // Tier 3
    ResearchEntry(id: 'focus_integrity', name: 'Focus Integrity Tracking', tier: 3, category: 'Context', description: 'Observable tracking of app foreground continuity and task switches.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.contextual, aliases: ['focus_continuity']),
    ResearchEntry(id: 'interruption_cost_tracking', name: 'Interruption Cost & Recovery', tier: 3, category: 'Context', description: 'Measuring post-interruption response latency and accuracy shifts.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.contextual, aliases: ['23_minute_interruption_recovery', 'interruption_cost']),
    ResearchEntry(id: 'sleep_context_association', name: 'Sleep Context Association', tier: 3, category: 'Context', description: 'User-reported sleep duration/quality correlated with delayed retention.', evidenceLevel: 4, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.contextual, aliases: ['sleep_observation']),
    ResearchEntry(id: 'exercise_context_association', name: 'Exercise Context Association', tier: 3, category: 'Context', description: 'Voluntary physical activity timing correlated against recall fluency.', evidenceLevel: 3, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.contextual, aliases: ['exercise_observation']),
    ResearchEntry(id: 'diurnal_timing', name: 'Diurnal Time-of-Day Analysis', tier: 3, category: 'Context', description: 'Tracking performance variations across morning, afternoon, and evening.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.contextual, aliases: ['morning_afternoon_timing', 'circadian_preference']),
    ResearchEntry(id: 'environment_context', name: 'Environmental Context Tracking', tier: 3, category: 'Context', description: 'Logging study environments to observe situational stability.', evidenceLevel: 3, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.contextual, aliases: ['green_urban_environments']),
    ResearchEntry(id: 'micro_offline_replay', name: 'Micro-Offline Replay', tier: 3, category: 'Retrieval', description: 'Ultra-short 15-30 second single-concept recall prompts operating offline.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['quick_replay', '10_second_waking_rests']),


    ResearchEntry(id: 'cued_retrieval', name: 'Cued Retrieval', tier: 1, category: 'Retrieval', description: 'Active memory retrieval prompted by a targeted cue.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['cued_recall']),
    // Tier 4
    ResearchEntry(id: 'personal_experiments', name: 'Personal Experiments Engine', tier: 4, category: 'Experimentation', description: 'Controlled and quasi-controlled A/B evaluations of study interventions.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['ab_testing', 'controlled_ab_comparisons']),
    ResearchEntry(id: 'biomarker_sensor_interface', name: 'Biomarker Sensor Interface', tier: 4, category: 'Hardware Abstraction', description: 'Data model abstraction for physiological streams (HRV, Pupillometry, fNIRS, EEG).', evidenceLevel: 3, implementationStatus: ImplementationStatus.instrumentationOnly, safetyLevel: SafetyClassification.sensorRequired, aliases: ['hrv', 'pupillometry', 'pupil_dilation', 'fnirs', 'bdnf', 'ctsb', 'dti', 'eeg_neurofeedback', 'theta_beta_ratio', 'tavns', 'vagus_nerve_stimulation']),
    ResearchEntry(id: 'neuroimaging_abstractions', name: 'Neuroimaging & Cellular Markers Abstraction', tier: 4, category: 'Research Abstraction', description: 'Interface specifications for lab-grade imaging (Diffusion-weighted imaging, CBTT, vMWM, OPC density, SWR metrics, Phase-Amplitude Coupling, PLV, Coherence).', evidenceLevel: 2, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.researchInstrumentation, aliases: ['diffusion_weighted_imaging', 'cbtt', 'vmwm', 'opc_density', 'swr_density_amplitude', 'phase_amplitude_coupling', 'plv', 'coherence', 'real_time_brain_state_decoding', 'astrocytic_calcium_imaging']),

    // Tier 5
    ResearchEntry(id: 'nsdr_protocol', name: 'Non-Sleep Deep Rest (NSDR / Yoga Nidra)', tier: 5, category: 'Physiological Priming', description: 'Safe guided behavioral rest protocol post-learning to facilitate micro-rest.', evidenceLevel: 4, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.safeSoftware, aliases: ['nsdr', 'yoga_nidra', 'nsdr_vs_short_nap']),
    ResearchEntry(id: 'autonomic_arousal_breathwork', name: 'Cyclic Sighing & Autonomic Regulation', tier: 5, category: 'Physiological Priming', description: 'Safe behavioral breathwork for downregulating acute stress.', evidenceLevel: 4, implementationStatus: ImplementationStatus.contextual, safetyLevel: SafetyClassification.safeSoftware, aliases: ['cyclic_sighing', 'autonomic_arousal_control', 'hyperventilation', 'visual_focus_aperture']),
    ResearchEntry(id: 'acoustic_slow_wave_stimulation', name: 'Acoustic Slow-Wave Stimulation', tier: 5, category: 'Neuromodulation', description: 'Auditory slow-wave phase-locked stimulation during deep sleep.', evidenceLevel: 3, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.researchInstrumentation),

    // Tier 6
    ResearchEntry(id: 'schema_instantiation', name: 'Schema Instantiation & Generative Transfer', tier: 6, category: 'Semantic Architecture', description: 'Organizing knowledge into relational graphs, analogies, and hierarchical models.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['generative_analogical_transfer', 'epistemic_foraging', 'curiosity_gaps', 'memory_reconsolidation', 'mild_stress_reconsolidation']),

    // Tier 7
    ResearchEntry(id: 'allostatic_load_management', name: 'Cognitive Load Shedding & Allostatic Regulation', tier: 7, category: 'Affective State', description: 'Monitoring subjective mental fatigue and cognitive friction to prevent burnout.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['cognitive_load_shedding', 'distributed_cognition', 'allostatic_load_index', 'socially_shared_regulation', 'brain_to_brain_synchrony']),
    // Tier 8
    ResearchEntry(id: 'cellular_plasticity_mechanisms', name: 'Cellular & Synaptic Plasticity Research', tier: 8, category: 'Cellular Neuroscience', description: 'Research metadata regarding Synaptic Tagging & Capture (STC), D1/D5 priming, Sharp-Wave Ripples (SWR), and Astrocyte metabolic support.', evidenceLevel: 2, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.medicalResearch, aliases: ['stc', 'synaptic_tagging_and_capture', 'd1_d5_priming', 'inverse_synaptic_tagging', 'awake_swr_maximization', 'waking_immobility', 'relative_immobility', 'large_swrs', 'glial_gated_plasticity', 'astrocyte_metabolic_support', 'astrocyte_ccn1', 'astrocytic_ephb3', 'tripartite_synapse', 'aerobic_intensity', 'astrocyte_mediated_working_memory_modulation', 'targeted_excitatory_stimulation', 'spiking_neuron_astrocyte_network_modeling', 'astrocytic_calcium_dynamics', 'inhibitory_stimulation_disruption']),

    // Tier 9
    ResearchEntry(id: 'productive_failure', name: 'Productive Failure & Prediction Errors', tier: 9, category: 'Predictive Processing', description: 'Engaging in challenging problem attempts before formal instruction to generate epistemic prediction errors.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['predictive_processing', 'productive_struggle', 'active_inference', 'vicarious_failure', 'de_novo_learning', 'metacognitive_friction', 'prediction_errors']),

    // Tier 10
    // Tier 11
    ResearchEntry(id: 'dynamic_ai_scaffolding', name: 'Dynamic AI Scaffolding & Socratic Dialogue', tier: 11, category: 'Cognitive Symbiosis', description: 'Adaptive AI support levels (None -> Hint -> Question -> Partial -> Worked Example -> Full) fading as mastery increases.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['socratic_co_reasoning', 'transactive_memory_shifting', 'dynamic_scaffolding', 'offloading_raw_data_to_vector_db', 'generative_spatial_knowledge_graphs', 'tms_genai_offloading']),

    // Tier 12
    ResearchEntry(id: 'ecm_pnn_mechanisms', name: 'Extracellular Matrix & Perineuronal Nets Research', tier: 12, category: 'Molecular Neuroscience', description: 'Biological research into perineuronal net (PNN) regulation and critical period plasticity.', evidenceLevel: 1, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.medicalResearch, aliases: ['downregulating_perineuronal_nets', 'pnn_degradation', 'extreme_environmental_enrichment', 'intense_motor_novelty', 'ca2_pnn_targeting', 'electroacupuncture_pnn_degradation', '4_mu']),

    // Tier 13
    ResearchEntry(id: 'adaptive_myelination_mechanisms', name: 'Adaptive Myelination & White Matter Tuning', tier: 13, category: 'Cellular Neuroscience', description: 'Activity-dependent myelination and oligodendrocyte progenitor cell (OPC) dynamics.', evidenceLevel: 2, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.medicalResearch, aliases: ['adaptive_myelination', 'experience_dependent_white_matter_tuning', 'opcs', 'oligodendrocyte_progenitor_cells', 'oligodendrogenesis', 'high_friction_multisensory_acquisition', 'activity_dependent_myelination', 'neural_transmission_velocity', 'myelination_metrics']),

    // Tier 14
    ResearchEntry(id: 'neural_oscillatory_dynamics', name: 'Theta-Gamma Phase-Amplitude Coupling & Oscillations', tier: 14, category: 'Electrophysiology', description: 'Electrophysiological phase-locking, hippocampal carrier waves, and whole-brain synchronization research.', evidenceLevel: 2, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.researchInstrumentation, aliases: ['theta_gamma_phase_amplitude_coupling', 'hippocampal_carrier_waves', 'forward_locomotion_spatial', 'transcranial_magneto_acoustic_stimulation', 'whole_brain_gamma_synchronization']),

    ResearchEntry(id: 'targeted_memory_reactivation', name: 'Targeted Memory Reactivation (TMR)', tier: 10, category: 'Sleep Augmentation', description: 'Replaying sensory cues paired with learning during slow-wave sleep via dedicated polysomnography hardware.', evidenceLevel: 3, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.researchInstrumentation, aliases: ['tmr', 'sleep_cue_reactivation', 'closed_loop_tmr', 'sensory_cues_during_sleep', 'closed_loop_phase_locked_stimulation', 'eeg_synchronized_acoustic_bursts', 'closed_loop_tmr_during_slow_wave_sleep', 'rem_sleep_tmr', 'microstructural_tmr_tracking', 'critical_reactivation_duration', 'phase_specific_motor_memory_consolidation', 'closed_loop_acoustic_stimulation', 'plas_in_older_adults', 'spindle_phase_relationships']),
    ResearchEntry(id: 'transcranial_stimulation', name: 'Transcranial Electrical/Magnetic Stimulation (TMS / tDCS / TUS / GVS)', tier: 10, category: 'Neuromodulation', description: 'Lab-grade non-invasive brain stimulation technologies. Strict research catalog item — no consumer DIY stimulation.', evidenceLevel: 2, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.invasiveOrHighRisk, aliases: ['gvs', 'noisy_gvs', 'home_based_gvs', 'tdcs_combination', 'tms', 'closed_loop_tms', 'concurrent_tms_fmri', 'real_time_decoder', 'personalized_network_guided_neuromodulation', 'optimal_stimulation_frequency', 'transcranial_focused_ultrasound', 'tus', 'theta_burst_tus', 'ventromedial_anterior_temporal_lobe_tus', 'amygdala_ultrasound_modulation', '40_200_hz_tus', 'gamma_entrainment', 'tacs_itbs', 'brain_chip_implants', 'bci', 'neuralink', 'optogenetics']),
    ResearchEntry(id: 'pharmacological_enhancers', name: 'Pharmacological & Nootropic Compounds', tier: 10, category: 'Pharmacology', description: 'Pharmaceutical neuroenhancers, racetam analogues, prescription stimulants, research peptides. Research catalog only.', evidenceLevel: 1, implementationStatus: ImplementationStatus.researchOnly, safetyLevel: SafetyClassification.pharmacological, aliases: ['pharmaceutical_neuroenhancers', 'modafinil', 'methylphenidate', 'piracetam_analogues', 'aniracetam', 'coluracetam', 'fasaracetam', 'nefiracetam', 'oxiracetam', 'phenylpiracetam', 'pramiracetam', 'psychostimulant_derivatives', 'research_peptides']),


    ResearchEntry(id: 'application_retrieval', name: 'Application Retrieval', tier: 1, category: 'Retrieval', description: 'Applying retrieved knowledge to solve novel problems.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['application']),
    ResearchEntry(id: 'corrective_feedback', name: 'Corrective Feedback', tier: 1, category: 'Feedback', description: 'Post-attempt error diagnosis highlighting missing points.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['feedback']),
    ResearchEntry(id: 'delayed_retrieval', name: 'Delayed Retrieval', tier: 1, category: 'Retrieval', description: 'Re-testing acquired concepts at delayed intervals.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['delayed_outcomes', 'delayed_test']),
    ResearchEntry(id: 'adaptive_spacing', name: 'Adaptive Spacing (FSRS)', tier: 1, category: 'Scheduling', description: 'Algorithmic interval scheduling via FSRS.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['fsrs', 'spaced_repetition']),
    ResearchEntry(id: 'temporal_to_semantic_spacing', name: 'Temporal-to-Semantic Spacing', tier: 1, category: 'Scheduling', description: 'Varying question framing across spaced intervals.', evidenceLevel: 4, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['semantic_spacing']),
    ResearchEntry(id: 'self_explanation', name: 'Self-Explanation', tier: 1, category: 'Metacognition', description: 'Explaining underlying causal principles in own words.', evidenceLevel: 5, implementationStatus: ImplementationStatus.implemented, safetyLevel: SafetyClassification.safeSoftware, aliases: ['feynman_technique']),
  ];
}
