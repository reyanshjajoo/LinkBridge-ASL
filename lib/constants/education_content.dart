import 'package:flutter/material.dart';

class HistoryFact {
  final IconData icon;
  final String title;
  final String description;

  const HistoryFact({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class SupportLink {
  final String title;
  final String urlText;
  final String url;

  const SupportLink({
    required this.title,
    required this.urlText,
    required this.url,
  });
}

class TriviaQuestion {
  final String question;
  final List<String> answers;
  final int correctIndex;

  const TriviaQuestion({
    required this.question,
    required this.answers,
    required this.correctIndex,
  });
}

const String educationIntroText =
    'This community spans every age and country. While it is often associated '
    'with older adults, millions of children and young adults are also part of '
    'this community and may face challenges in education and social integration.';

const List<HistoryFact> historyFacts = <HistoryFact>[
  HistoryFact(
    icon: Icons.gavel,
    title: 'Legal hurdles',
    description:
        'In the 6th century, the Justinian Code often denied property and marriage '
        'rights to deaf individuals who could not speak, creating a long-standing '
        'legal stigma.',
  ),
  HistoryFact(
    icon: Icons.block,
    title: 'The ban on signs',
    description:
        'At the 1880 Milan Conference, educators voted to ban sign language in '
        'schools, pushing oralism and weakening Deaf culture for decades.',
  ),
  HistoryFact(
    icon: Icons.groups_2_outlined,
    title: 'Martha\'s Vineyard',
    description:
        'In the 1700s, hereditary deafness was common enough that many hearing '
        'residents used sign language, creating a highly accessible community.',
  ),
];

const List<String> allyTips = <String>[
  'Get attention with a gentle tap or wave.',
  'Face the person so they can see your expressions.',
  'If asked to repeat, do not say “nevermind.”',
];

const List<SupportLink> supportLinks = <SupportLink>[
  SupportLink(
    title: 'Hearing Health Foundation',
    urlText: 'hearinghealthfoundation.org',
    url: 'https://hearinghealthfoundation.org',
  ),
  SupportLink(
    title: 'Global Deaf Research',
    urlText: 'globaldeafresearch.org',
    url: 'https://globaldeafresearch.org/',
  ),
  SupportLink(
    title: 'Global Deaf Research Institute',
    urlText: 'deaforganizationsfund.org',
    url: 'https://deaforganizationsfund.org/npo/global-deaf-research-institute/',
  ),
];

const List<TriviaQuestion> triviaQuestions = <TriviaQuestion>[
  TriviaQuestion(
    question: 'What percent of Deaf children have hearing parents?',
    answers: <String>['20%', '50%', '90%', '75%'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    question: 'Where was the first US Deaf school founded?',
    answers: <String>['New York City', 'Hartford', 'Washington D.C.', 'Boston'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    question: 'Who signed the Gallaudet charter?',
    answers: <String>[
      'Abraham Lincoln',
      'George Washington',
      'Thomas Jefferson',
      'Andrew Jackson',
    ],
    correctIndex: 0,
  ),
  TriviaQuestion(
    question: 'ASL is most similar to sign language from:',
    answers: <String>['United Kingdom', 'Mexico', 'France', 'Germany'],
    correctIndex: 0,
  ),
  TriviaQuestion(
    question: 'The “Deaf President Now” protest happened in:',
    answers: <String>['1972', '1988', '2001', '1964'],
    correctIndex: 1,
  ),
];
