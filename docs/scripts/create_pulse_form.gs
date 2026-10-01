// Run in Google Apps Script. This script has not been run by the project author.
function createPulseForm() {
  const form = FormApp.create('AI context friction: a one-minute research survey');
  form.setDescription('This student survey is for adults 18 or older. We ask whether you gave an AI tool the same details more than once. We do not ask for your name, email, or employer. The research team will store answers in its Google account and share group results. You can leave before you send the form. This sample does not speak for all workers.');
  form.setCollectEmail(false);
  form.setProgressBar(true);
  form.setConfirmationMessage('Thank you for taking part.');
  const consent = form.addMultipleChoiceItem().setTitle('1. Are you 18 or older, and do you agree to take part?').setRequired(true);
  const questions = form.addPageBreakItem().setTitle('AI use in the last seven days');
  consent.setChoices([consent.createChoice('Yes',questions),consent.createChoice('No',FormApp.PageNavigationType.SUBMIT)]);
  form.addMultipleChoiceItem().setTitle('2. Where do you use AI most?').setChoiceValues(['Paid work','Education or training','Personal use','I do not use AI','Prefer not to say']).setRequired(true);
  form.addMultipleChoiceItem().setTitle('3. In the last seven days, did you use a generative AI tool?').setChoiceValues(['Yes','No','Unsure']).setRequired(true);
  form.addMultipleChoiceItem().setTitle('4. In those seven days, did you re-enter background information that you had already given an AI tool?').setChoiceValues(['Yes','No','Unsure','I did not use AI']).setRequired(true);
  form.addTextItem().setTitle('5. Approximately how many minutes did you spend re-entering background information into AI tools in those seven days?').setHelpText('Optional. Enter a whole number from 0 to 10080. Leave blank if unsure or you did not use AI.').setValidation(FormApp.createTextValidation().requireTextMatchesPattern('^(0|[1-9][0-9]{0,3}|100[0-7][0-9]|10080)$').build());
  form.addMultipleChoiceItem().setTitle('6. Which tool did you use most in those seven days?').setChoiceValues(['ChatGPT','Claude','Gemini','Microsoft Copilot','GitHub Copilot','Grok','DeepSeek','Perplexity','Other','Prefer not to answer / not applicable']);
  const sheet = SpreadsheetApp.create('AI context friction survey — responses');
  form.setDestination(FormApp.DestinationType.SPREADSHEET,sheet.getId());
  Logger.log('Edit form: '+form.getEditUrl());
  Logger.log('Response link (check publishing and access): '+form.getPublishedUrl());
  Logger.log('Responses: '+sheet.getUrl());
}
