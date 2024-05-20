
//Made by Sachin Dhami

import SwiftUI
import Network

struct QuizCategory: Identifiable, Codable {
    let id = UUID()
    let title: String
    let desc: String
    let questions: [Question]
}

struct GradientText: View {
    var text: String
    var gradient: Gradient

    var body: some View {
        Text(text)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(
                LinearGradient(
                    gradient: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}



struct HomeView: View {
    @State private var showingPopover = false
    @State private var newURL = "https://tednewardsandbox.site44.com/questions.json"
    @State private var quizCategories: [QuizCategory] = []
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List(quizCategories) { category in
                NavigationLink(destination: QuestionListView(category: category)) {
                    QuizCategoryRow(category: category)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ), lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    GradientText(
                        text: "Quizzes for iQuiz!",
                        gradient: Gradient(colors: [Color.blue.opacity(0.7)])
                    )
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPopover = true
                    }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                    .popover(isPresented: $showingPopover, arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Enter/paste data link:")
                                .font(.headline)

                            TextField("Enter URL", text: $newURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            Button(action: {
                                dataLink(from: newURL)
                                showingPopover = false
                            }) {
                                Text("Check Now")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .frame(width: 300)
                    }
                }
            }
            .onAppear {
                dataLink(from: newURL)
            }
            .alert(isPresented: Binding<Bool>(
                get: { alertMessage != "" },
                set: { _,_  in })) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }





struct QuizCategoryRow: View {
    let category: QuizCategory
    
    var body: some View {
        HStack {
            // Using conditional statements to determine which image from system to display
            if category.title == "Mathematics" {
                Image(systemName: "number.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
            } else if category.title == "Marvel Super Heroes" {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
            } else if category.title == "Science!" {
                Image(systemName: "atom")
                    .resizable()
                    .frame(width: 30, height: 30)
            } else {
                // Default image if none of the conditions are met
                Image(systemName: "sparkles")
                    .resizable()
                    .frame(width: 30, height: 30)
            }
            
            VStack(alignment: .leading) {
                Text(category.title)
                    .font(.headline)
                Text(category.desc)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

    func dataLink(from url: String) {
        guard let url = URL(string: url) else {
            alertMessage = "Invalid URL"
            return
        }
        
        if !Reachability.isConnectedToNetwork() {
            alertMessage = "No internet connection"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let quizData = try decoder.decode([QuizCategory].self, from: data)
                    DispatchQueue.main.async {
                        self.quizCategories = quizData
                        UserDefaults.standard.set(url.absoluteString, forKey: "quizDataURL")
                    }
                } catch {
                    alertMessage = "JSON decoding error: \(error.localizedDescription)"
                }
            } else if let error = error {
                alertMessage = "Error fetching data: \(error.localizedDescription)"
            }
        }.resume()
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}



struct Question: Codable {
    let text: String
    let answer: String
    let answers: [String]
}


struct QuestionListView: View {
    let category: QuizCategory
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [String?] = []
    @State private var isAnswerViewPresented = false
    @State private var userScore = 0
    @State private var selectedAnswerIndex: Int?
    
    var totalQuestions: Int {
        category.questions.count
    }
    
    var currentQuestion: Question {
        category.questions[currentQuestionIndex]
    }
    
    var body: some View {
        VStack {
            if currentQuestionIndex < category.questions.count {
                if isAnswerViewPresented {
                    AnswerView(question: currentQuestion, correctAnswer: currentQuestion.answers[Int(currentQuestion.answer)! - 1], userAnswer: userAnswers[currentQuestionIndex], dismissAction: {
                        isAnswerViewPresented = false
                        currentQuestionIndex += 1
                    })
                } else {
                    QuestionView(question: currentQuestion, selectedAnswerIndex: $selectedAnswerIndex)
                    Button("Submit") {
                        if let selectedAnswerIndex = selectedAnswerIndex {
                            let userAnswer = currentQuestion.answers[selectedAnswerIndex]
                            userAnswers.append(userAnswer)
                            if userAnswer == currentQuestion.answers[Int(currentQuestion.answer)! - 1] {
                                userScore += 1
                            }
                            isAnswerViewPresented = true
                        }
                    }
                    .padding()
                    .disabled(selectedAnswerIndex == nil)
                }
            } else {
                ScoreView(score: userScore, totalQuestions: totalQuestions)
            }
        }
    }
}



struct QuestionView: View {
    let question: Question
    @Binding var selectedAnswerIndex: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.text)
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                )
                .padding(.horizontal)
            
            ForEach(question.answers.indices, id: \.self) { index in
                AnswerButton(
                    isSelected: selectedAnswerIndex == index,
                    action: { selectedAnswerIndex = index },
                    text: question.answers[index]
                )
            }
            
            Spacer()
        }
        .padding()
    }
}



struct AnswerButton: View {
    let isSelected: Bool
    let action: () -> Void
    let text: String

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                Text(text)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.clear)
                    .shadow(color: isSelected ? Color.green.opacity(0.5) : Color.clear, radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}



struct Reachability {
    static func isConnectedToNetwork() -> Bool {
        return true
    }
}

struct AnswerView: View {
    let question: Question
    let correctAnswer: String
    let userAnswer: String?
    let dismissAction: () -> Void
    
    var isAnswerCorrect: Bool {
        userAnswer == correctAnswer
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Question")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .accessibility(label: Text("Question"))
                
                Text(question.text)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Correct Answer")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .accessibility(label: Text("Correct Answer"))
                
                Text(correctAnswer)
                    .foregroundColor(.green)
                    .font(.title)
                    .padding()
                
                if !isAnswerCorrect {
                    Text("Your Answer: \(userAnswer ?? "No Answer")")
                        .foregroundColor(.red)
                        .font(.title)
                        .padding()
                        .accessibility(label: Text("Your Answer: \(userAnswer ?? "No Answer")"))
                }
                
                if isAnswerCorrect {
                    Text("+1")
                        .foregroundColor(.green)
                        .font(.title)
                        .padding()
                        .accessibility(hidden: true) // Hide this text from accessibility
                }
                
                Button(action: dismissAction) {
                    Text("Next")
                        .foregroundColor(.white)
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .accessibility(label: Text("Next"))
            }
            .padding()
        }
    }
}





struct ScoreView: View {
    let score: Int
    let totalQuestions: Int
    
    private var scorePercentage: Double {
        return Double(score) / Double(totalQuestions)
    }
    
    private var scoreText: String {
        switch scorePercentage {
        case 1.0:
            return "Perfect Score! WOW!"
        case 0.9..<1.0:
            return "Almost there! Just missed a few."
        case 0.7..<0.9:
            return "Good effort"
        case 0.5..<0.7:
            return "Nice"
        default:
            return "Brush up on your skills!"
        }
    }
    
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: 3) // Adding blur effect
            
            VStack {
                Text(scoreText)
                    .font(.title)
                    .padding()
                    .foregroundColor(scoreColor())
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2, x: 0, y: 2) // Adding shadow effect
                
                Text("You answered \(score) out of \(totalQuestions) questions correctly.")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2, x: 0, y: 2) // Adding shadow effect
            }
            .padding()
        }
    }
    
    private func scoreColor() -> Color {
        switch scorePercentage {
        case 1.0:
            return .green
        case 0.7..<1.0:
            return .blue
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
}




