//import Foundation
//import Network
//
//struct QuizTopic: Identifiable {
//    let id = UUID()
//    let icon: String
//    let title: String
//    let description: String
//}
//
//struct QuizQuestion: Identifiable, Codable {
//    let id = UUID()
//    let question: String
//    let options: [String]
//    let correctAnswer: String
//    
//    enum CodingKeys: String, CodingKey {
//        case question
//        case options = "answers"
//        case correctAnswer = "answer"
//    }
//}
//
//import Foundation
//import Combine
//
//class QuizDataFetcher: ObservableObject {
//    @Published var questions: [QuizQuestion] = []
//    @Published var errorMessage: String?
//    
//    private var cancellable: AnyCancellable?
//    
//    func fetchData(from urlString: String) {
//        guard let url = URL(string: urlString) else {
//            errorMessage = "Invalid URL"
//            return
//        }
//        
//        cancellable = URLSession.shared.dataTaskPublisher(for: url)
//            .map(\.data)
//            .decode(type: [QuizQuestion].self, decoder: JSONDecoder())
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                case .finished:
//                    break
//                }
//            }, receiveValue: { questions in
//                self.questions = questions
//                self.errorMessage = nil
//            })
//    }
//}
//
//import SwiftUI
//
//struct SettingsView: View {
//    @AppStorage("quizDataURL") private var quizDataURL: String = "https://tednewardsandbox.site44.com/questions.json"
//    @ObservedObject var dataFetcher: QuizDataFetcher
//    
//    @State private var tempURL: String = ""
//    
//    var body: some View {
//        VStack {
//            TextField("Quiz Data URL", text: $tempURL)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//            
//            Button(action: {
//                if let url = URL(string: tempURL), UIApplication.shared.canOpenURL(url) {
//                    quizDataURL = tempURL
//                    dataFetcher.fetchData(from: tempURL)
//                } else {
//                    dataFetcher.errorMessage = "Invalid URL"
//                }
//            }) {
//                Text("Check Now")
//            }
//            .padding()
//            
//            if let errorMessage = dataFetcher.errorMessage {
//                Text(errorMessage).foregroundColor(.red)
//            }
//        }
//        .onAppear {
//            tempURL = quizDataURL
//        }
//    }
//}
//
//
//import SwiftUI
//
//struct ContentView: View {
//    @ObservedObject var dataFetcher = QuizDataFetcher()
//    @State private var showSettings = false
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(dataFetcher.questions) { question in
//                    NavigationLink(destination: QuizView(topic: QuizTopic(icon: "questionmark.circle", title: question.question, description: "Answer the question"), questions: [question])) {
//                        HStack {
//                            Image(systemName: "questionmark.circle")
//                            VStack(alignment: .leading) {
//                                Text(question.question).font(.headline)
//                                Text("Answer the question").font(.subheadline)
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("iQuiz")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        showSettings.toggle()
//                    }) {
//                        Text("Settings")
//                    }
//                }
//            }
//            .onAppear {
//                dataFetcher.fetchData(from: UserDefaults.standard.string(forKey: "quizDataURL") ?? "http://tednewardsandbox.site44.com/questions.json")
//            }
//            .alert(isPresented: Binding<Bool>.constant(dataFetcher.errorMessage != nil)) {
//                Alert(title: Text("Error"), message: Text(dataFetcher.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
//            }
//            .sheet(isPresented: $showSettings) {
//                SettingsView(dataFetcher: dataFetcher)
//            }
//        }
//    }
//}
//
//
//struct QuizView: View {
//    let topic: QuizTopic
//    let questions: [QuizQuestion]
//    
//    @State private var currentQuestionIndex = 0
//    @State private var score = 0
//    @State private var showResult = false
//    
//    var body: some View {
//        if showResult {
//            ResultView(score: score, total: questions.count)
//        } else {
//            QuestionView(question: questions[currentQuestionIndex],
//                         questions: questions,
//                         currentIndex: currentQuestionIndex,
//                         score: $score,
//                         showResult: $showResult,
//                         nextQuestion: {
//                            if currentQuestionIndex + 1 < questions.count {
//                                currentQuestionIndex += 1
//                            } else {
//                                showResult = true
//                            }
//                         })
//        }
//    }
//}
//
//
//struct QuestionView: View {
//    let question: QuizQuestion
//    let questions: [QuizQuestion]
//    let currentIndex: Int
//    @Binding var score: Int
//    @Binding var showResult: Bool
//    let nextQuestion: () -> Void
//    
//    @State private var selectedAnswer: String? = nil
//    @State private var showAnswer = false
//    
//    var body: some View {
//        VStack {
//            Text(question.question).font(.title).padding()
//            ForEach(question.options, id: \.self) { option in
//                Button(action: {
//                    selectedAnswer = option
//                }) {
//                    HStack {
//                        Text(option)
//                        Spacer()
//                        if selectedAnswer == option {
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                    .padding()
//                    .background(Color(UIColor.systemGray6))
//                    .cornerRadius(8)
//                }
//            }
//            Button(action: {
//                if selectedAnswer != nil {
//                    showAnswer = true
//                }
//            }) {
//                Text("Submit")
//            }
//            .padding()
//            .sheet(isPresented: $showAnswer, onDismiss: {
//                if currentIndex + 1 < questions.count {
//                    nextQuestion()
//                } else {
//                    showResult = true
//                }
//            }) {
//                AnswerView(question: question, selectedAnswer: selectedAnswer!, score: $score)
//            }
//        }
//        .navigationBarBackButtonHidden(true)
//    }
//}
//
//struct AnswerView: View {
//    let question: QuizQuestion
//    let selectedAnswer: String
//    @Binding var score: Int
//    
//    var body: some View {
//        VStack {
//            Text(question.question).font(.title).padding()
//            ForEach(question.options, id: \.self) { option in
//                HStack {
//                    Text(option)
//                    Spacer()
//                    if option == question.correctAnswer {
//                        Image(systemName: "checkmark.circle.fill")
//                    } else if option == selectedAnswer {
//                        Image(systemName: "xmark.circle.fill")
//                    }
//                }
//                .padding()
//                .background(Color(UIColor.systemGray6))
//                .cornerRadius(8)
//            }
//            Text(selectedAnswer == question.correctAnswer ? "Correct!" : "Wrong!").font(.headline).padding()
//            Button(action: {
//                if selectedAnswer == question.correctAnswer {
//                    score += 1
//                }
//            }) {
//                Text("Next")
//            }
//            .padding()
//        }
//    }
//}
//
//struct ResultView: View {
//    let score: Int
//    let total: Int
//    
//    var body: some View {
//        VStack {
//            Text("Quiz Finished!").font(.title).padding()
//            Text("You scored \(score) out of \(total)").font(.headline).padding()
//            Button(action: {
//                // Navigate back to the quiz list
//                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                   let window = windowScene.windows.first {
//                    window.rootViewController?.dismiss(animated: true, completion: nil)
//                }
//            }) {
//                Text("Back to Quiz List")
//            }
//            .padding()
//        }
//    }
//}























import SwiftUI
import Network

struct QuizCategory: Identifiable, Codable {
    let id = UUID()
    let title: String
    let desc: String
    let questions: [Question]
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
                }
            }
            .navigationBarTitle("Quizzes for iQuiz!")
            .navigationBarItems(trailing:
                Button(action: {
                    showingPopover = true
                }) {
                    Text("Settings")
                }
                .popover(isPresented: $showingPopover, arrowEdge: .trailing) {
                    VStack {
                        Text("Enter/paste data link:")
                        TextField("Enter URL", text: $newURL).textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Button("Check Now") {
                            getData(from: newURL)
                            showingPopover = false
                        }
                        .padding()
                    }
                }
            )
            .onAppear {
                getData(from: newURL)
            }
            .alert(isPresented: Binding<Bool>(
                get: { alertMessage != "" },
                set: { _,_  in })) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }



    
    func getData(from url: String) {
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



struct QuizCategoryRow: View {
    let category: QuizCategory
    
    var body: some View {
        HStack {
            // Use conditional statements to determine which image to display
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
                FinishedView(score: userScore, totalQuestions: totalQuestions)
            }
        }
    }
}


//struct QuestionView: View {
//    let question: Question
//    @Binding var selectedAnswerIndex: Int?
//    
//    var body: some View {
//        VStack {
//            Text(question.text)
//                .font(.title)
//                .padding()
//            
//            ForEach(question.answers.indices, id: \.self) { index in
//                Button(action: {
//                    selectedAnswerIndex = index
//                }) {
//                    HStack {
//                        Image(systemName: selectedAnswerIndex == index ? "checkmark.circle.fill" : "circle")
//                            .foregroundColor(selectedAnswerIndex == index ? .green : .gray)
//                        Text(question.answers[index])
//                            .multilineTextAlignment(.leading)
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .background(selectedAnswerIndex == index ? Color.gray.opacity(0.2) : Color.clear)
//                    .cornerRadius(8)
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//            
//            Spacer()
//        }
//        .padding()
//    }
//}
struct QuestionView: View {
    let question: Question
    @Binding var selectedAnswerIndex: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.text)
                .font(.title)
                .padding()
            
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
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}




//struct AnswerView: View {
//    let question: Question
//    let correctAnswer: String
//    let userAnswer: String?
//    let dismissAction: () -> Void
//    
//    var isAnswerCorrect: Bool {
//        userAnswer == correctAnswer
//    }
//    
//    var body: some View {
//        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
//                .edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 20) {
//                Text("Question")
//                    .font(.title)
//                    .foregroundColor(.white)
//                    .padding()
//                    .accessibility(label: Text("Question"))
//                
//                Text(question.text)
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                    .padding()
//                
//                Text("Correct Answer")
//                    .font(.title)
//                    .foregroundColor(.white)
//                    .padding()
//                    .accessibility(label: Text("Correct Answer"))
//                
//                Text(correctAnswer)
//                    .foregroundColor(.green)
//                    .font(.title)
//                    .padding()
//                
//                if !isAnswerCorrect {
//                    Text("Your Answer: \(userAnswer ?? "No Answer")")
//                        .foregroundColor(.red)
//                        .font(.title)
//                        .padding()
//                        .accessibility(label: Text("Your Answer: \(userAnswer ?? "No Answer")"))
//                }
//                
//                if isAnswerCorrect {
//                    Text("+1")
//                        .foregroundColor(.green)
//                        .font(.title)
//                        .padding()
//                        .accessibility(hidden: true) // Hide this text from accessibility
//                }
//                
//                Button(action: dismissAction) {
//                    Text("Next")
//                        .foregroundColor(.white)
//                        .font(.title)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.green)
//                        .cornerRadius(10)
//                }
//                .accessibility(label: Text("Next"))
//            }
//            .padding()
//        }
//    }
//}
//
//
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





struct FinishedView: View {
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




