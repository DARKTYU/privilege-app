const _englishReply =
    'I am sorry you are going through this. If you or someone else is in immediate danger, contact local emergency services now. Please reach out to a trusted person and stay with them if you can.';
const _arabicReply =
    'أنا آسف لأنك تمر بهذا. إذا كنت أنت أو شخص آخر في خطر فوري، اتصل بخدمات الطوارئ المحلية الآن. تواصل مع شخص تثق به وابق معه إن أمكن.';

final _english = RegExp(
    r"\b(?:suicid(?:e|al)|kill myself|end my life|hurt myself|self[\s-]?harm|want to die|overdos(?:e|ed|ing)|chest pain|pain in (?:my |the )?chest|cannot breathe|can['’]t breathe|trouble breathing|difficulty breathing|short(?:ness)? of breath|not breathing|end it all|take my own life|don['’]t want to live|no reason to live|hurting myself|cut myself|cutting myself|having a heart attack|having a stroke|passed out|fainted|bleeding heavily|bleeding badly)\b");
final _arabic = RegExp(
    r'انتحار|انتحر|اقتل نفسي|هقتل نفسي|هموت نفسي|اموت نفسي|عايز(?:ه|ة)? اموت|نفسي اموت|اذي نفسي|هاذي نفسي|ايذاء نفسي|جرعة زائدة|جرعة زايدة|الم في الصدر|الم (?:في )?صدري|وجع (?:في )?صدري|صدري (?:بيوجعني|وجعني)|وجع في الصدر|ضيق (?:في )?التنفس|صعوبة (?:في )?التنفس|لا استطيع التنفس|لا اقدر اتنفس|مش قادر(?:ه|ة)? اتنفس|مش عارف(?:ه|ة)? اتنفس|مش عارف(?:ه|ة)? اخد نفسي|نفسي (?:مقطوع|ضيق)|مش بتنفس|لا يتنفس|هنتحر|هانتحر|مش عايز اعيش|مش عايزه اعيش|اخلص علي نفسي|ازمة قلبية|جلطة|اغمي علي|نزيف شديد');
final _arabicCharacters = RegExp(r'[\u0600-\u06ff]');

bool containsArabic(String text) => _arabicCharacters.hasMatch(text);

String? coachEmergencyReply(String text) {
  // Dart has no built-in NFKC; normalize Arabic marks, alef and ya manually.
  // This keyword list is incomplete and cannot detect every emergency.
  final normalized = text
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064b-\u065f\u0670\u0640]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي');
  if (!_english.hasMatch(normalized) && !_arabic.hasMatch(normalized)) {
    return null;
  }
  return containsArabic(normalized) ? _arabicReply : _englishReply;
}
