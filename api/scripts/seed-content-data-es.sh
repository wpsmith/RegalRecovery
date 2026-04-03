#!/usr/bin/env bash
# Seed regal-recovery-content-es database with all 12 collections (Spanish)
set -euo pipefail

echo "Sembrando base de datos regal-recovery-content-es..."
echo ""

docker compose exec -T mongodb mongosh regal-recovery-content-es --eval '
db.dropDatabase();
print("✓ Base de datos de contenido existente eliminada para sembrado nuevo");
print("");

var now = ISODate("2026-04-03T00:00:00Z");
var base = { tenantId: "SYSTEM", status: "published", createdAt: now, modifiedAt: now };

db.feature_abouts.insertMany([
  { ...base, slug: "faster-scale", title: "Comprendiendo la Escala FASTER", summary: "La Escala FASTER ayuda a identificar dónde te encuentras en el ciclo de recaída.", contentHtml: "<p>Desarrollada por Michael Dye, la Escala FASTER mapea seis etapas progresivas que conducen a la recaída.</p>", category: "activity", relatedFeatureFlag: "activity.faster-scale", iconName: "speedometer", sortOrder: 1 },
  { ...base, slug: "triggers", title: "Comprendiendo los Desencadenantes", summary: "Aprende a identificar y manejar los desencadenantes que preceden el comportamiento compulsivo.", contentHtml: "<p>En recuperación, un desencadenante es cualquier estado interno o estímulo externo que activa el impulso de actuar.</p>", category: "tool", relatedFeatureFlag: "feature.triggers", iconName: "alert-triangle", sortOrder: 1 },
  { ...base, slug: "3circles", title: "Los Tres Círculos", summary: "Una herramienta de establecimiento de límites para categorizar comportamientos en círculos internos, medios y externos.", contentHtml: "<p>El modelo de Los Tres Círculos categoriza comportamientos en círculos internos (actuar), medios (advertencia) y externos (saludables).</p>", category: "tool", relatedFeatureFlag: "feature.three-circles", iconName: "circles", sortOrder: 2 },
  { ...base, slug: "evening-review", title: "Revisión Nocturna", summary: "Un inventario estructurado de fin de día para la sobriedad, honestidad y salud emocional.", contentHtml: "<p>La revisión nocturna es la práctica diaria del Paso 10 — un balance honesto de fin de día.</p>", category: "activity", relatedFeatureFlag: "activity.check-ins", iconName: "moon", sortOrder: 2 },
  { ...base, slug: "urge-logging", title: "Registro de Impulsos", summary: "Rastrea impulsos con intensidad, desencadenantes y resultados para revelar patrones.", contentHtml: "<p>Registrar impulsos construye autoconciencia y revela patrones con el tiempo.</p>", category: "activity", relatedFeatureFlag: "activity.urge-logging", iconName: "flame", sortOrder: 3 },
  { ...base, slug: "journaling", title: "Diario de Recuperación", summary: "Procesa pensamientos y emociones a través de escritura guiada o libre.", contentHtml: "<p>El diario es una práctica fundamental de recuperación para procesar emociones y rastrear el crecimiento.</p>", category: "activity", relatedFeatureFlag: "activity.journaling", iconName: "book-open", sortOrder: 4 },
  { ...base, slug: "fanos", title: "Check-In FANOS", summary: "Un marco estructurado para comunicación honesta: Sentimientos, Apreciación, Necesidades, Responsabilidad, Sobriedad.", contentHtml: "<p>FANOS proporciona una estructura segura para compartir con tu cónyuge o compañero de rendición de cuentas.</p>", category: "communication", relatedFeatureFlag: "activity.fanos", iconName: "message-circle", sortOrder: 1 },
  { ...base, slug: "fitnap", title: "Check-In FITNAP", summary: "Un marco alternativo de check-in: Sentimientos, Intimidad, Desencadenantes, Necesidades, Afirmaciones, Oración.", contentHtml: "<p>FITNAP es una alternativa a FANOS con discusión explícita de desencadenantes y un componente espiritual.</p>", category: "communication", relatedFeatureFlag: "activity.fitnap", iconName: "message-square", sortOrder: 2 },
  { ...base, slug: "pci", title: "Índice de Locura Personal", summary: "Rastrea 10 comportamientos de advertencia personalizados que señalan vulnerabilidad creciente.", contentHtml: "<p>Creado por Patrick Carnes, el PCI mide la manejabilidad general de la vida a través de dimensiones conductuales.</p>", category: "activity", relatedFeatureFlag: "activity.pci", iconName: "activity", sortOrder: 5 },
  { ...base, slug: "sobriety-commitment", title: "Compromiso de Sobriedad", summary: "Declara tu compromiso diario con la sobriedad como ancla de recuperación.", contentHtml: "<p>El compromiso de sobriedad es una declaración diaria que ancla tu intención de recuperación.</p>", category: "activity", relatedFeatureFlag: "activity.sobriety-commitment", iconName: "shield", sortOrder: 6 },
  { ...base, slug: "affirmations", title: "Afirmaciones Diarias", summary: "Afirmaciones basadas en las Escrituras para renovar tu mente e identidad.", contentHtml: "<p>Las afirmaciones diarias combaten las mentiras de la adicción con la verdad bíblica sobre tu identidad.</p>", category: "content", relatedFeatureFlag: "activity.affirmations", iconName: "sun", sortOrder: 1 },
  { ...base, slug: "devotionals", title: "Devocionales Diarios", summary: "Escritura, reflexión y oración para tu jornada de recuperación.", contentHtml: "<p>Los devocionales diarios proporcionan reflexión basada en las Escrituras específica para temas de recuperación.</p>", category: "content", relatedFeatureFlag: "feature.content-resources", iconName: "book", sortOrder: 2 },
  { ...base, slug: "step-work", title: "Trabajo de los 12 Pasos", summary: "Diario guiado a través de los 12 Pasos de recuperación.", contentHtml: "<p>Los 12 Pasos te guían desde admitir la impotencia hasta el despertar espiritual y el servicio.</p>", category: "content", relatedFeatureFlag: "activity.step-work", iconName: "list-ordered", sortOrder: 3 },
  { ...base, slug: "acting-in", title: "Actuando Internamente", summary: "Rastrea comportamientos sutiles de adicción internalizada que ocurren dentro de las relaciones.", contentHtml: "<p>Actuar internamente se refiere a comportamientos sutiles como el retraimiento emocional, la deshonestidad por omisión y la manipulación.</p>", category: "activity", relatedFeatureFlag: "activity.acting-in", iconName: "eye-off", sortOrder: 7 },
  { ...base, slug: "arousal-template", title: "Plantilla de Excitación", summary: "Mapea los patrones de pensamientos, sentimientos y situaciones que alimentan el comportamiento compulsivo.", contentHtml: "<p>Desarrollada por Patrick Carnes, la plantilla de excitación describe tu constelación única de desencadenantes.</p>", category: "tool", relatedFeatureFlag: "feature.arousal-template", iconName: "map", sortOrder: 3 },
  { ...base, slug: "relapse-prevention", title: "Plan de Prevención de Recaídas", summary: "Un plan estructurado de desencadenantes, estrategias de afrontamiento y contactos de emergencia.", contentHtml: "<p>Tu plan de prevención de recaídas es tu estrategia de defensa personalizada para situaciones de alto riesgo.</p>", category: "tool", relatedFeatureFlag: "feature.relapse-prevention", iconName: "shield-check", sortOrder: 4 },
  { ...base, slug: "vision-statement", title: "Declaración de Visión", summary: "Escribe la visión del hombre en que te estás convirtiendo en la recuperación.", contentHtml: "<p>Tu declaración de visión describe la vida que la recuperación está haciendo posible — fundamentada y honesta.</p>", category: "tool", relatedFeatureFlag: "feature.vision-statement", iconName: "target", sortOrder: 5 },
  { ...base, slug: "mood-tracking", title: "Seguimiento del Estado de Ánimo", summary: "Califica y rastrea tu estado emocional a lo largo del día.", contentHtml: "<p>El seguimiento regular del estado de ánimo construye conciencia emocional — una habilidad central de recuperación.</p>", category: "activity", relatedFeatureFlag: "activity.mood-tracking", iconName: "smile", sortOrder: 8 },
  { ...base, slug: "gratitude-list", title: "Lista de Gratitud", summary: "Captura aquello por lo que estás agradecido para cambiar el enfoque de la lucha a la bendición.", contentHtml: "<p>La práctica de gratitud recablea el cerebro alejándolo del sesgo negativo y hacia la esperanza.</p>", category: "activity", relatedFeatureFlag: "activity.gratitude", iconName: "heart", sortOrder: 9 },
  { ...base, slug: "prayer", title: "Oración", summary: "Registra tu práctica de oración y rastrea el compromiso espiritual.", contentHtml: "<p>La oración es el salvavidas de la recuperación — tu comunicación directa con Dios.</p>", category: "activity", relatedFeatureFlag: "activity.prayer", iconName: "hands", sortOrder: 10 },
  { ...base, slug: "meetings", title: "Asistencia a Reuniones", summary: "Rastrea la asistencia a reuniones de 12 pasos y recuperación.", contentHtml: "<p>La asistencia regular a reuniones es uno de los predictores más fuertes de recuperación sostenida.</p>", category: "activity", relatedFeatureFlag: "activity.meetings", iconName: "users", sortOrder: 11 },
  { ...base, slug: "exercise", title: "Ejercicio", summary: "Registra la actividad física que apoya la recuperación y la regulación emocional.", contentHtml: "<p>El ejercicio libera endorfinas, reduce el estrés y reconstruye las vías cerebrales dañadas por la adicción.</p>", category: "activity", relatedFeatureFlag: "activity.exercise", iconName: "dumbbell", sortOrder: 12 },
  { ...base, slug: "time-journal", title: "Diario de Tiempo", summary: "Check-ins basados en intervalos que capturan ubicación, emoción y actividad a lo largo del día.", contentHtml: "<p>El diario de tiempo es una actividad de diario estructurada basada en intervalos para reconocimiento de patrones.</p>", category: "activity", relatedFeatureFlag: "activity.time-journal", iconName: "clock", sortOrder: 13 },
  { ...base, slug: "emotional-journal", title: "Diario Emocional", summary: "Capturas rápidas de conciencia emocional con ubicación y selfie opcionales.", contentHtml: "<p>El diario emocional está diseñado para conciencia emocional frecuente y de baja fricción a lo largo del día.</p>", category: "activity", relatedFeatureFlag: "activity.emotional-journal", iconName: "heart-pulse", sortOrder: 14 },
  { ...base, slug: "post-mortem", title: "Análisis Post-Mortem", summary: "Reflexión estructurada después de una recaída para aprender y prevenir recurrencia.", contentHtml: "<p>Una recaída no es un fracaso — es información. El post-mortem te ayuda a aprender de lo que sucedió.</p>", category: "activity", relatedFeatureFlag: "activity.post-mortem", iconName: "search", sortOrder: 15 },
  { ...base, slug: "sast-r", title: "Evaluación SAST-R", summary: "Una herramienta de detección validada para evaluar patrones de adicción sexual.", contentHtml: "<p>La Prueba de Detección de Adicción Sexual (Revisada) mide patrones de comportamiento a través de múltiples dimensiones.</p>", category: "assessment", relatedFeatureFlag: "activity.sast-r", iconName: "clipboard-check", sortOrder: 1 },
  { ...base, slug: "denial", title: "Evaluación de Negación", summary: "Identifica patrones de negación que bloquean la autoevaluación honesta.", contentHtml: "<p>La negación es el mecanismo de defensa principal de la adicción — reconocerla es el primer paso hacia la libertad.</p>", category: "assessment", relatedFeatureFlag: "activity.denial", iconName: "shield-off", sortOrder: 2 },
  { ...base, slug: "rl-backbone", title: "Columna Vertebral", summary: "Construye tu columna vertebral de recuperación diaria — las prácticas no negociables que sostienen la libertad.", contentHtml: "<p>Tu columna vertebral es el conjunto de prácticas diarias de recuperación a las que te comprometes sin importar qué.</p>", category: "activity", relatedFeatureFlag: "activity.backbone", iconName: "spine", sortOrder: 16 },
  { ...base, slug: "memory-verse", title: "Revisión de Versículos Memorizados", summary: "Memoriza y revisa versículos de las Escrituras que anclan tu recuperación.", contentHtml: "<p>La memorización de las Escrituras renueva la mente y proporciona verdad para combatir el pensamiento adictivo.</p>", category: "activity", relatedFeatureFlag: "activity.memory-verse", iconName: "bookmark", sortOrder: 17 },
  { ...base, slug: "nutrition", title: "Nutrición", summary: "Rastrea comidas y hábitos alimenticios que apoyan la recuperación física.", contentHtml: "<p>La nutrición adecuada estabiliza el azúcar en la sangre, apoya la curación del cerebro y reduce la vulnerabilidad a los desencadenantes.</p>", category: "activity", relatedFeatureFlag: "activity.nutrition", iconName: "apple", sortOrder: 18 },
  { ...base, slug: "book-reading", title: "Lectura de Libros", summary: "Rastrea el progreso de lectura de recuperación y espiritual.", contentHtml: "<p>Leer literatura de recuperación y las Escrituras profundiza la comprensión y refuerza los principios de recuperación.</p>", category: "activity", relatedFeatureFlag: "activity.book-reading", iconName: "book-open-check", sortOrder: 19 }
]);
print("✓ Creadas 31 descripciones de funciones");

db.affirmation_packs.insertOne({
  ...base, packId: "pack_christian", name: "Christian Affirmations",
  description: "44 afirmaciones bíblicas para la recuperación diaria",
  tier: "standard", price: 0, currency: "USD", affirmationCount: 5,
  category: "christian", thumbnailUrl: "", sortOrder: 1
});
print("✓ Creado paquete de afirmaciones: Christian Affirmations");

db.affirmations.insertMany([
  { ...base, affirmationId: "aff_001", packId: "pack_christian", statement: "Soy formidable y maravillosamente hecho.", scriptureReference: "Salmo 139:14", category: "identity", language: "es", sortOrder: 1 },
  { ...base, affirmationId: "aff_002", packId: "pack_christian", statement: "Todo lo puedo en Cristo que me fortalece.", scriptureReference: "Filipenses 4:13", category: "strength", language: "es", sortOrder: 2 },
  { ...base, affirmationId: "aff_003", packId: "pack_christian", statement: "El Señor es mi pastor; nada me faltará.", scriptureReference: "Salmo 23:1", category: "peace", language: "es", sortOrder: 3 },
  { ...base, affirmationId: "aff_004", packId: "pack_christian", statement: "Dios es mi refugio y fortaleza, una ayuda siempre presente en problemas.", scriptureReference: "Salmo 46:1", category: "strength", language: "es", sortOrder: 4 },
  { ...base, affirmationId: "aff_005", packId: "pack_christian", statement: "Soy una nueva creación en Cristo; lo viejo ha pasado.", scriptureReference: "2 Corintios 5:17", category: "identity", language: "es", sortOrder: 5 }
]);
print("✓ Creadas 5 afirmaciones");

db.devotional_packs.insertOne({
  ...base, packId: "dpack_foundations", name: "Foundations",
  description: "Devocionales fundamentales para el viaje de recuperación",
  tier: "standard", price: 0, currency: "USD", devotionalCount: 3,
  category: "core", thumbnailUrl: "", sortOrder: 1
});
print("✓ Creado paquete de devocionales: Foundations");

db.devotionals.insertMany([
  { ...base, devotionalId: "dev_001", packId: "dpack_foundations", day: 1, title: "Un Nuevo Comienzo", scripture: "2 Corintios 5:17", scriptureText: "Por lo tanto, si alguno está en Cristo, nueva criatura es; las cosas viejas pasaron; he aquí, son hechas nuevas.", reflection: "Cada día en recuperación es un nuevo comienzo. Dios no nos define por nuestros fracasos pasados sino por Su amor redentor.", prayerPrompt: "Señor, ayúdame a abrazar este nuevo comienzo." },
  { ...base, devotionalId: "dev_002", packId: "dpack_foundations", day: 2, title: "Fuerza para el Viaje", scripture: "Isaías 40:31", scriptureText: "Pero los que esperan en el Señor renovarán sus fuerzas.", reflection: "La recuperación requiere rendición diaria. Cuando ponemos nuestra esperanza en el Señor, Él nos renueva.", prayerPrompt: "Padre, renueva mi fuerza hoy mientras pongo mi esperanza en Ti." },
  { ...base, devotionalId: "dev_003", packId: "dpack_foundations", day: 3, title: "Libertad de la Vergüenza", scripture: "Romanos 8:1", scriptureText: "Por lo tanto, ahora no hay condenación para los que están en Cristo Jesús.", reflection: "La vergüenza es el enemigo de la recuperación. Dios ha quitado nuestra condenación a través de Jesús.", prayerPrompt: "Dios, líbrame del peso de la vergüenza y ayúdame a caminar en Tu gracia." }
]);
print("✓ Creados 3 devocionales");

db.journal_prompts.insertMany([
  { ...base, promptId: "prompt_001", text: "¿Por qué estoy más agradecido hoy, y cuál fue la parte más difícil de mi día?", category: "daily", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_002", text: "¿Qué desencadenantes encontré hoy, y cómo respondí?", category: "sobriety", tags: ["FASTER", "triggers"], sortOrder: 1 },
  { ...base, promptId: "prompt_003", text: "¿Qué emociones estoy experimentando ahora mismo? ¿Dónde las siento en mi cuerpo?", category: "emotional", tags: ["FANOS/FITNAP"], sortOrder: 1 },
  { ...base, promptId: "prompt_004", text: "¿Qué relación me trajo alegría hoy? ¿Qué relación me desafió?", category: "relationships", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_005", text: "¿Cómo experimenté a Dios hoy? ¿Dónde vi Su mano en acción?", category: "spiritual", tags: ["12-Step"], sortOrder: 1 }
]);
print("✓ Creadas 5 indicaciones de diario");

db.glossary_terms.insertMany([
  { ...base, termId: "term_faster", term: "Escala FASTER", definition: "Una herramienta de conciencia de recaída desarrollada por Michael Dye que mapea seis etapas progresivas que conducen a la recaída: Olvidar Prioridades, Ansiedad, Acelerándose, Enojado, Exhausto, Recaída.", relatedSlugs: ["faster-scale"], sortOrder: 1 },
  { ...base, termId: "term_fanos", term: "FANOS", definition: "Un marco estructurado de check-in para parejas: Sentimientos, Afirmaciones, Necesidades, Responsabilidad, Sobriedad.", relatedSlugs: ["fanos"], sortOrder: 2 },
  { ...base, termId: "term_3circles", term: "3 Círculos", definition: "Una herramienta de establecimiento de límites donde los comportamientos se categorizan en círculos internos (actuar), medios (advertencia) y externos (saludables).", relatedSlugs: ["3circles"], sortOrder: 3 },
  { ...base, termId: "term_pci", term: "PCI", definition: "Índice de Locura Personal — una herramienta de autoevaluación de Patrick Carnes que mide la manejabilidad general de la vida.", relatedSlugs: ["pci"], sortOrder: 4 },
  { ...base, termId: "term_sastr", term: "SAST-R", definition: "Prueba de Detección de Adicción Sexual (Revisada) — un instrumento de detección clínica validado para la adicción sexual.", relatedSlugs: ["sast-r"], sortOrder: 5 }
]);
print("✓ Creados 5 términos del glosario");

db.evening_review_questions.insertMany([
  { ...base, questionId: "erq_001", text: "¿Estuve sobrio hoy en pensamiento, palabra y acción?", dimension: "sobriety", sortOrder: 1 },
  { ...base, questionId: "erq_002", text: "¿Fui completamente honesto hoy — sin mentiras, omisiones o secretos?", dimension: "sobriety", sortOrder: 2 },
  { ...base, questionId: "erq_003", text: "¿Qué emociones experimenté hoy? ¿Puedo nombrar al menos tres?", dimension: "emotional", sortOrder: 1 },
  { ...base, questionId: "erq_004", text: "¿Traté a las personas a mi alrededor con respeto y amabilidad hoy?", dimension: "relational", sortOrder: 1 },
  { ...base, questionId: "erq_005", text: "¿Pasé tiempo con Dios hoy — en oración, escritura o escucha silenciosa?", dimension: "spiritual", sortOrder: 1 },
  { ...base, questionId: "erq_006", text: "¿Trabajé mi plan de recuperación hoy?", dimension: "recovery", sortOrder: 1 },
  { ...base, questionId: "erq_007", text: "¿Dónde estoy en la Escala FASTER ahora mismo, honestamente?", dimension: "faster-scale", sortOrder: 1 },
  { ...base, questionId: "erq_008", text: "¿Qué es una cosa que necesito hacer diferente mañana?", dimension: "looking-forward", sortOrder: 1 }
]);
print("✓ Creadas 8 preguntas de revisión nocturna");

db.acting_in_behaviors.insertMany([
  { ...base, behaviorId: "aib_001", name: "Culpar", description: "", sortOrder: 1 },
  { ...base, behaviorId: "aib_002", name: "Avergonzar", description: "", sortOrder: 2 },
  { ...base, behaviorId: "aib_003", name: "Criticar", description: "", sortOrder: 3 },
  { ...base, behaviorId: "aib_004", name: "Cerrar", description: "", sortOrder: 4 },
  { ...base, behaviorId: "aib_005", name: "Evitar", description: "", sortOrder: 5 },
  { ...base, behaviorId: "aib_006", name: "Esconder", description: "", sortOrder: 6 },
  { ...base, behaviorId: "aib_007", name: "Mentir", description: "", sortOrder: 7 },
  { ...base, behaviorId: "aib_008", name: "Excusar", description: "", sortOrder: 8 },
  { ...base, behaviorId: "aib_009", name: "Manipular", description: "", sortOrder: 9 },
  { ...base, behaviorId: "aib_010", name: "Controlar con Ira", description: "", sortOrder: 10 },
  { ...base, behaviorId: "aib_011", name: "Pasividad", description: "", sortOrder: 11 },
  { ...base, behaviorId: "aib_012", name: "Humor", description: "", sortOrder: 12 },
  { ...base, behaviorId: "aib_013", name: "Aplacar", description: "", sortOrder: 13 },
  { ...base, behaviorId: "aib_014", name: "Retener Amor/Sexo", description: "", sortOrder: 14 },
  { ...base, behaviorId: "aib_015", name: "HiperEspiritualizar", description: "", sortOrder: 15 }
]);
print("✓ Creados 15 comportamientos de actuar internamente");

db.needs.insertMany([
  { ...base, needId: "need_001", name: "Aceptación", description: "", sortOrder: 1 },
  { ...base, needId: "need_002", name: "Afirmación", description: "", sortOrder: 2 },
  { ...base, needId: "need_003", name: "Agencia", description: "", sortOrder: 3 },
  { ...base, needId: "need_004", name: "Pertenencia", description: "", sortOrder: 4 },
  { ...base, needId: "need_005", name: "Consuelo", description: "", sortOrder: 5 },
  { ...base, needId: "need_006", name: "Compasión", description: "", sortOrder: 6 },
  { ...base, needId: "need_007", name: "Conexión", description: "", sortOrder: 7 },
  { ...base, needId: "need_008", name: "Empatía", description: "", sortOrder: 8 },
  { ...base, needId: "need_009", name: "Aliento", description: "", sortOrder: 9 },
  { ...base, needId: "need_010", name: "Perdón", description: "", sortOrder: 10 },
  { ...base, needId: "need_011", name: "Gracia", description: "", sortOrder: 11 },
  { ...base, needId: "need_012", name: "Esperanza", description: "", sortOrder: 12 },
  { ...base, needId: "need_013", name: "Amor", description: "", sortOrder: 13 },
  { ...base, needId: "need_014", name: "Paz", description: "", sortOrder: 14 },
  { ...base, needId: "need_015", name: "Tranquilidad", description: "", sortOrder: 15 },
  { ...base, needId: "need_016", name: "Respeto", description: "", sortOrder: 16 },
  { ...base, needId: "need_017", name: "Seguridad", description: "", sortOrder: 17 },
  { ...base, needId: "need_018", name: "Protección", description: "", sortOrder: 18 },
  { ...base, needId: "need_019", name: "Comprensión", description: "", sortOrder: 19 },
  { ...base, needId: "need_020", name: "Validación", description: "", sortOrder: 20 }
]);
print("✓ Creadas 20 necesidades");

db.sobriety_reset_messages.insertMany([
  { ...base, messageId: "srm_001", text: "Sus misericordias son nuevas esta mañana — y tú también lo eres.", scriptureReference: "Lamentaciones 3:22-23", sortOrder: 1 },
  { ...base, messageId: "srm_002", text: "Un reinicio no es el final de tu historia. Es un punto de inflexión. Dios todavía está escribiendo.", scriptureReference: "", sortOrder: 2 },
  { ...base, messageId: "srm_003", text: "No estás definido por tu peor momento. Estás definido por Aquel que te llama Suyo.", scriptureReference: "", sortOrder: 3 },
  { ...base, messageId: "srm_004", text: "El justo puede caer siete veces pero aún se levanta.", scriptureReference: "Proverbios 24:16", sortOrder: 4 },
  { ...base, messageId: "srm_005", text: "Ahora mismo, la gracia es más fuerte que la vergüenza.", scriptureReference: "", sortOrder: 5 },
  { ...base, messageId: "srm_006", text: "Dios no se estremeció. Él sabía que este día vendría, y todavía está aquí, todavía está contigo, todavía está obrando.", scriptureReference: "", sortOrder: 6 },
  { ...base, messageId: "srm_007", text: "Por lo tanto, ahora no hay condenación para los que están en Cristo Jesús.", scriptureReference: "Romanos 8:1", sortOrder: 7 },
  { ...base, messageId: "srm_008", text: "Tuviste el coraje de ser honesto. Eso importa más de lo que sabes.", scriptureReference: "", sortOrder: 8 },
  { ...base, messageId: "srm_009", text: "Este reinicio no borra el crecimiento que vino antes. Cada día sobrio todavía contó.", scriptureReference: "", sortOrder: 9 },
  { ...base, messageId: "srm_010", text: "Él sana a los quebrantados de corazón y venda sus heridas.", scriptureReference: "Salmo 147:3", sortOrder: 10 }
]);
print("✓ Creados 10 mensajes de reinicio de sobriedad");

db.themes.insertMany([
  { ...base, themeId: "theme_light", name: "Light", description: "Tema predeterminado limpio y brillante", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1E3A5F", secondary: "#4A90D9", accent: "#F5A623", background: "#FFFFFF", surface: "#F5F5F5", text: "#1A1A1A", textSecondary: "#666666" }, previewUrl: "", sortOrder: 1 },
  { ...base, themeId: "theme_dark", name: "Dark", description: "Tema oscuro fácil para los ojos", tier: "standard", price: 0, currency: "USD", colors: { primary: "#4A90D9", secondary: "#1E3A5F", accent: "#F5A623", background: "#121212", surface: "#1E1E1E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 2 },
  { ...base, themeId: "theme_midnight", name: "Midnight", description: "Tema oscuro azul marino profundo", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1A1A2E", secondary: "#16213E", accent: "#0F3460", background: "#0A0A1A", surface: "#1A1A2E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 3 }
]);
print("✓ Creados 3 temas");

print("");
print("=============================================================================");
print("✅ SEMBRADO DE BASE DE DATOS DE CONTENIDO COMPLETO");
print("=============================================================================");
print("");
print("Colecciones sembradas:");
print("  - Descripciones de Funciones: 31");
print("  - Paquetes de Afirmaciones: 1");
print("  - Afirmaciones: 5");
print("  - Paquetes de Devocionales: 1");
print("  - Devocionales: 3");
print("  - Indicaciones de Diario: 5");
print("  - Términos del Glosario: 5");
print("  - Preguntas de Revisión Nocturna: 8");
print("  - Comportamientos de Actuar Internamente: 15");
print("  - Necesidades: 20");
print("  - Mensajes de Reinicio de Sobriedad: 10");
print("  - Temas: 3");
'

echo ""
echo "¡Sembrado de base de datos de contenido completo!"
