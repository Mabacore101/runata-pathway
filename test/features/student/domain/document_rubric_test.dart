import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/features/student/domain/document_rubric.dart';

/// Finds one scored criterion by its title, so tests read by intent
/// ("the length criterion") rather than by fragile array index.
ScoredCriterion _find(DocScore score, String titleContains) {
  return score.results.firstWhere((r) => r.title.contains(titleContains));
}

void main() {
  group('wordCount', () {
    test('counts whitespace-separated tokens', () {
      expect(wordCount('hello world'), 2);
      expect(wordCount('  hello   world  '), 2);
      expect(wordCount(''), 0);
      expect(wordCount('   '), 0);
      expect(wordCount('one'), 1);
    });
  });

  group('paragraphCount', () {
    test('counts blank-line-separated blocks', () {
      expect(paragraphCount('Para one.\n\nPara two.\n\nPara three.'), 3);
    });

    test('multiple blank lines between paragraphs still count as one break',
        () {
      expect(paragraphCount('Para one.\n\n\nPara two.'), 2);
    });

    test('leading/trailing blank sections are not counted as paragraphs',
        () {
      expect(paragraphCount('\n\nPara one.\n\n'), 1);
    });

    test('a single block with no blank-line break counts as 1', () {
      expect(paragraphCount('Just one paragraph, no breaks at all.'), 1);
    });

    test('empty text has 0 paragraphs', () {
      expect(paragraphCount(''), 0);
    });
  });

  group('escapeForRegex', () {
    test('escapes every regex metacharacter the JS esc() escapes', () {
      const special = 'C++ (Hons.) [Track A]';
      final escaped = escapeForRegex(special);

      // The escaped string must be safely usable as a RegExp pattern
      // (would throw on unescaped brackets/parens) and must match the
      // literal original text, not some other interpretation of it.
      final re = RegExp(escaped, caseSensitive: false);
      expect(re.hasMatch('I am applying for the $special program.'), isTrue);
    });

    test('a plain alphanumeric string round-trips unchanged', () {
      expect(escapeForRegex('Computer Science'), 'Computer Science');
    });
  });

  group('scoreDoc — unknown or upload-kind doc keys', () {
    test('an unknown docKey returns met=0, total=0, no results', () {
      final score = scoreDoc('nonexistent', 'some text', DocumentScoringContext.empty);
      expect(score.total, 0);
      expect(score.met, 0);
      expect(score.results, isEmpty);
    });

    test('recletter (upload-kind) has no RUBRIC entry, same as the JS '
        'RUBRIC[k]||[] fallback', () {
      final score = scoreDoc('recletter', 'some text', DocumentScoringContext.empty);
      expect(score.total, 0);
      expect(score.met, 0);
    });
  });

  group('scoreDoc — empty text scores 0 for every text-kind doc', () {
    for (final key in ['personal', 'commonapp', 'studyplan', 'sop', 'cv']) {
      test('$key: empty text meets 0 of its criteria', () {
        final score = scoreDoc(key, '', DocumentScoringContext.empty);
        expect(score.met, 0);
        expect(score.total, greaterThan(0));
      });

      test('$key: null text behaves the same as empty text', () {
        final score = scoreDoc(key, null, DocumentScoringContext.empty);
        expect(score.met, 0);
      });
    }
  });

  group('scoreDoc — personal (real sample text)', () {
    // Verified word count 458 (within 450-700) and 4 paragraphs before
    // being embedded here.
    const sample =
        'Ever since I built my first robot out of spare Lego pieces at age nine, I have been fascinated by how machines can be taught to solve problems on their own. That early curiosity turned into a genuine passion for computer science, one that has only grown stronger through every project I have taken on since, and it now shapes almost every choice I make about how I spend my free time outside of school.\n'
        '\n'
        'In my final two years of school, I led a team of four students in a regional robotics competition, where we designed and programmed an autonomous sorting arm from scratch. When I hit a wall debugging our sensor calibration two days before the deadline, I spent an entire weekend rewriting our control loop, testing each change against the same three obstacle courses over and over until the timing finally felt right. The arm worked exactly as intended on the day of the competition, and we went on to win second place out of eighteen teams from across the region. More importantly than the result itself, I discovered how much I genuinely enjoy the slow, sometimes frustrating process of taking a rough sketch on paper and turning it into something that actually functions reliably in the real world.\n'
        '\n'
        'Outside of competitions, I also founded a small coding club at school to teach younger students the basics of Python, an experience that taught me as much about patient communication as it did about programming itself. Explaining a loop or a conditional statement to a twelve-year-old who has never touched a keyboard before forces you to understand the idea far more deeply than any exam ever could, and watching students who started the term afraid of the terminal end it by building their own simple games was one of the most rewarding things I have done. Running the club for a full academic year also meant learning how to plan sessions, manage a modest budget for equipment, and keep a group of very different personalities engaged week after week.\n'
        '\n'
        'I have come to realise that the course I want to study is not just about writing code, but about understanding the systems that code controls and the people those systems ultimately serve. That is exactly what a Computer Science degree at university would let me explore in far greater depth, moving from the small, self-contained projects I have built so far toward genuinely complex, collaborative systems. Studying this field would let me combine the analytical rigour I developed through the robotics competition with the creative problem solving I have always been drawn to since childhood, and I am ready to bring that same persistence and curiosity to a university programme that challenges me every single day.';

    test('word count and paragraph count are what the criteria expect', () {
      expect(wordCount(sample), inInclusiveRange(450, 700));
      expect(paragraphCount(sample), greaterThanOrEqualTo(3));
    });

    test('meets all 6 criteria (met == total)', () {
      final score = scoreDoc('personal', sample, DocumentScoringContext.empty);
      expect(score.total, 6);
      expect(score.met, 6);
      expect(score.results.every((r) => r.met), isTrue);
    });

    test('the "Connects to the chosen course" criterion can also be met '
        'purely via a matching ctx.major, with no static keyword present',
        () {
      const snippet =
          'Robotics has captivated me since childhood, and Physics is the subject I want to spend my life exploring.';
      // Sanity: this snippet deliberately contains none of the static
      // keywords (course/programme/program/degree/field/study).
      final withoutCtx = scoreDoc('personal', snippet, DocumentScoringContext.empty);
      expect(_find(withoutCtx, 'Connects to the chosen course').met, isFalse);

      final withCtx = scoreDoc(
        'personal',
        snippet,
        const DocumentScoringContext(major: 'Physics'),
      );
      expect(_find(withCtx, 'Connects to the chosen course').met, isTrue);
    });

    test('the length criterion uses the JS\'s actual 450–700 bound, not '
        'the 450–650 the label states — this mismatch is preserved '
        'verbatim from the source', () {
      bool metAt(int words) {
        final text = List.filled(words, 'word').join(' ');
        final score = scoreDoc('personal', text, DocumentScoringContext.empty);
        return _find(score, 'Right length').met;
      }

      expect(metAt(449), isFalse);
      expect(metAt(450), isTrue);
      expect(metAt(700), isTrue);
      expect(metAt(701), isFalse); // would fail if the label's 650 were used
    });
  });

  group('scoreDoc — commonapp (real sample text)', () {
    const sample =
        "I remember standing in the doorway of my grandmother's kitchen, seven years old, watching her fold dozens of small paper boats out of old newspaper while she waited for news about a flood in her home village. She was not anxious in the way I expected; she was calm, humming softly, hands moving as though the folding itself was the point. I did not understand it then, but I have thought about that image constantly ever since.\n"
        '\n'
        'Growing up, I assumed calm under pressure was something people either had or did not have, a fixed trait rather than a skill. It was only after I spent three months last year volunteering at a local shelter during an unusually severe rainy season, coordinating supply drop-offs for 40 families a night, that I realised how wrong that assumption was. I learned that my grandmother\'s calm was not innate at all. It was built, deliberately, out of small repeated rituals that gave her hands something steady to do while her mind waited.\n'
        '\n'
        'Once I understood that, I started noticing the same pattern everywhere, including in myself. Before a difficult exam or a hard conversation, I now find some small, specific task, tidying my desk, rereading one paragraph of notes, checking a single number twice, because I finally realised that the task itself is not really the point either. Now I understand what my grandmother was teaching me that whole time, even though neither of us called it a lesson: that steadiness is something you make, one small folded boat at a time.';

    test('meets all 5 criteria (met == total)', () {
      final score = scoreDoc('commonapp', sample, DocumentScoringContext.empty);
      expect(score.total, 5);
      expect(score.met, 5);
    });
  });

  group('scoreDoc — studyplan (real sample text)', () {
    const sample =
        'I completed my high school education at a science-track SMA in Jakarta, where my strongest subjects were mathematics, physics, and economics, consistently finishing near the top of my grade in all three across every semester. Alongside regular coursework, I also completed an additional statistics elective in my final year and took part in a small student research group analysing local air quality data, which is what first pushed me toward the field of data science, and it is also why I have chosen to apply to study in China specifically rather than staying closer to home.\n'
        '\n'
        'Beyond the general academic reputation of the university itself, I chose this country because of the scale and speed of its technology sector, which gives students direct access to industry partnerships and internships that are much harder to find elsewhere in the region. Several universities I researched also offer joint programmes with local technology companies during the third year of study, something I have not found matched anywhere else on my shortlist, and the scale of real-world data these companies work with is simply not something a smaller market can offer a student at my stage. My objective for the first two years of the programme is to build a solid foundation in statistics and programming, before choosing to focus on applied machine learning in my final two years through elective coursework and a capstone project supervised directly by faculty rather than a generic group assignment.\n'
        '\n'
        'After graduation, my career goal is to return home and work within the fintech sector, applying data science methods to expand access to financial services for small businesses that are currently underserved by traditional banks and formal lending institutions. I intend to spend my first few years after graduating gaining hands-on experience at a mid-sized fintech company, learning how data products are actually built, tested, and deployed at scale, before eventually aiming for a role where I can help shape how these products are designed from the ground up rather than only maintaining systems that already exist. Studying abroad first, in a market moving this quickly, feels like the fastest way to gain that depth of experience before bringing it home.\n'
        '\n'
        'I have discussed this plan with two of my current teachers, both of whom studied abroad themselves, and their advice shaped how I structured my application and my choice of university within the country. I am confident that the combination of a strong academic foundation, a clear objective for each stage of the programme, and a specific plan for what comes after graduation makes me a genuinely well-prepared candidate for this course of study, not simply someone applying because the country is currently a popular choice among my peers.';

    test('meets all 5 criteria via the static "china" fallback keyword '
        '(no ctx needed)', () {
      final score = scoreDoc('studyplan', sample, DocumentScoringContext.empty);
      expect(score.total, 5);
      expect(score.met, 5);
    });

    test('the country criterion is also met via a matching ctx.country '
        'on text that omits every static fallback keyword', () {
      const snippet =
          'My grades in mathematics and economics have prepared me well for a rigorous undergraduate programme, and I am ready for the challenge ahead.';
      final withoutCtx = scoreDoc('studyplan', snippet, DocumentScoringContext.empty);
      expect(_find(withoutCtx, 'Why this country').met, isFalse);

      final withCtx = scoreDoc(
        'studyplan',
        snippet,
        const DocumentScoringContext(country: 'Germany'),
      );
      // Still false — the snippet doesn't mention Germany either.
      expect(_find(withCtx, 'Why this country').met, isFalse);

      final withMention = scoreDoc(
        'studyplan',
        '$snippet I have selected Germany specifically for its strong engineering programmes.',
        const DocumentScoringContext(country: 'Germany'),
      );
      expect(_find(withMention, 'Why this country').met, isTrue);
    });
  });

  group('scoreDoc — sop (real sample text)', () {
    const sample =
        "My goal in applying to this program is to deepen the applied statistics background I began building during my final years of school, with the aim of eventually working in public health research across Southeast Asia. I am specifically drawn to this faculty's ongoing focus on epidemiological modelling, which fits closely with the direction I want my own work to take over the next several years, and which very few other programs I researched combine with this much hands-on fieldwork built directly into the coursework itself.\n"
        '\n'
        "This program is a particularly strong fit for me because of the faculty's research output in infectious disease modelling, an area I first encountered while volunteering with a local health NGO for eight months, where I helped clean and organise vaccination records for a rural clinic serving roughly 3,000 residents across several surrounding villages. That experience of working with imperfect, real-world data taught me lessons no classroom exercise could, specifically how much of applied statistics is really about carefully understanding the data and the people behind it before ever attempting to build a model from it, something I did not fully appreciate until I was the one entering the numbers myself.\n"
        '\n'
        'I am not interested in research for its own sake; I want to work on problems with a specific, measurable impact on real communities, and this program\'s emphasis on applied fieldwork alongside rigorous coursework is exactly the combination I have been looking for since I first started researching graduate programs nearly two years ago. Talking with current students in the program only confirmed that this balance is a genuine, lived part of how the faculty actually teaches, not just a claim made in a brochure, and that reassurance mattered a great deal in narrowing down my final list of applications this year.\n'
        '\n'
        'Outside of the NGO work, I also spent a semester assisting a university researcher part-time with data entry for a separate nutrition study, an experience that reinforced just how much careful, unglamorous groundwork sits underneath any published finding. I am applying to this program specifically because it treats that groundwork as central to the training itself, rather than as something students only encounter later in their careers. I have also started learning R specifically to prepare for the kind of coursework this program requires, working through two online modules on my own over the past few months so that I arrive with at least a basic working knowledge rather than starting entirely from zero.';

    test('meets all 5 criteria (met == total)', () {
      final score = scoreDoc('sop', sample, DocumentScoringContext.empty);
      expect(score.total, 5);
      expect(score.met, 5);
    });

    test('the "Fit with the program" criterion can also be met purely via '
        'a matching ctx.major, with no static keyword present', () {
      const snippet =
          'My aspiration is to grow within Economics, a subject I have loved since childhood and hope to pursue for life.';
      final withoutCtx = scoreDoc('sop', snippet, DocumentScoringContext.empty);
      expect(_find(withoutCtx, 'Fit with the program').met, isFalse);

      final withCtx = scoreDoc(
        'sop',
        snippet,
        const DocumentScoringContext(major: 'Economics'),
      );
      expect(_find(withCtx, 'Fit with the program').met, isTrue);
    });
  });

  group('scoreDoc — cv (real sample text)', () {
    const sample =
        'Education: Jakarta International SMA, graduating 2026, GPA 3.8/4.0. Contact: student.example@email.com.\n'
        '\n'
        'Activities: President of the school Coding Club (2 years); volunteer tutor for younger students in mathematics; committee member for the annual school science fair; completed a 6-week summer internship at a local software startup.\n'
        '\n'
        'Skills: Proficient in Python and SQL; conversational in Mandarin and English; comfortable with basic data visualisation tools including Excel and Tableau.\n'
        '\n'
        'Achievements: Won second place in a regional robotics competition; certificate of completion for an online machine learning course; named finalist in a national coding competition.';

    test('meets all 5 criteria (met == total)', () {
      final score = scoreDoc('cv', sample, DocumentScoringContext.empty);
      expect(score.total, 5);
      expect(score.met, 5);
    });

    test('the concise criterion requires > 0 words, not just <= 600 — an '
        'empty CV should not count as "concise"', () {
      final empty = scoreDoc('cv', '', DocumentScoringContext.empty);
      expect(_find(empty, 'Concise').met, isFalse);

      bool metAt(int words) {
        final text = List.filled(words, 'word').join(' ');
        final score = scoreDoc('cv', text, DocumentScoringContext.empty);
        return _find(score, 'Concise').met;
      }

      expect(metAt(600), isTrue);
      expect(metAt(601), isFalse);
    });
  });

  group('scoreDoc — partial credit', () {
    test('a doc meeting some but not all criteria reports an accurate '
        'met/total split, not all-or-nothing', () {
      // Deliberately hits motivation + skills keywords but is far too
      // short and has no course/degree mention and only 1 paragraph.
      const partial =
          'I am passionate about this field and have won several awards for my work.';

      final score = scoreDoc('personal', partial, DocumentScoringContext.empty);

      expect(score.total, 6);
      expect(score.met, greaterThan(0));
      expect(score.met, lessThan(score.total));
      expect(_find(score, 'motivation').met, isTrue);
      expect(_find(score, 'skills or achievements').met, isTrue);
      expect(_find(score, 'Right length').met, isFalse);
      expect(_find(score, 'structure').met, isFalse);
    });
  });

  group('docInfo', () {
    test('has an entry for all 6 doc kinds, including recletter (which has '
        'no RUBRIC entry)', () {
      for (final key in ['personal', 'commonapp', 'studyplan', 'sop', 'cv', 'recletter']) {
        expect(docInfo[key], isNotNull, reason: 'missing docInfo for $key');
        expect(docInfo[key], contains('<b>'));
      }
    });
  });

  group('matStatusOrder', () {
    test('matches the JS MATSTAT order exactly', () {
      expect(matStatusOrder, ['Not started', 'Draft', 'In review', 'Final']);
    });
  });
}
