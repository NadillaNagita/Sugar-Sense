class RegistrationData {
  String? docID;
  String? firstName; // Dari FirstNameScreen
  String? goal; // Dari GoalScreen
  String? targetWeight; // Dari WeightScreen
  String? currentWeight; // Dari CurrentWeightScreen
  String? height; // Dari HeightScreen
  String? gender; // Dari GenderScreen
  String? activityLevel; // Dari ActivityLevelScreen
  DateTime? dateOfBirth; // Dari FinalSubmissionScreen

  String? email; // Dari CreateAccountEmailScreen
  String? password; // Dari CreateAccountPasswordScreen
  String? name;
  bool isGoogleSignIn;
  bool isFacebookSignIn; // Dari CreateAccountNameScreen

  RegistrationData({
    this.docID,
    this.firstName,
    this.goal,
    this.targetWeight,
    this.currentWeight,
    this.height,
    this.gender,
    this.activityLevel,
    this.dateOfBirth,
    this.email,
    this.password,
    this.name,
    this.isGoogleSignIn = false,
    this.isFacebookSignIn = false,
  });
}
