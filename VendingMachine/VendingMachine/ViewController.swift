import UIKit

class ViewController: UIViewController {
    
    /*
     1. 음료수의 재고상태를 State에 추가하세요
     2. 음료수의 재고를 채워넣기 위한 Input 명령을 추가해 넣으세요
     3. 현재 음료수 개수에 따라 음료수 부족 에러를 추가해 넣으세요
     4. 음료수가 출력되면 재고도 함께 차감되도록 하세요
     */

    // MARK: - MODEL

    enum Product: Int, CaseIterable {
        case cola = 1000
        case cider = 1100
        case fanta = 1200
        func name() -> String {
            switch self {
            case .cola: return "콜라"
            case .cider: return "사이다"
            case .fanta: return "환타"
            }
        }
    }

    enum Input {
        case moneyInput(Int)
        case productSelect(Product)
        case reset
        case none
        case addInventory
    }

    enum Output {
        case displayMoney(Int)
        case productOut(Product)
        case shortMoneyError
        case change(Int)
        case shortStockError(Product)
        case displayProductStock(Int)
    }

    struct State {
        let money: Int
        let stocks : [Product : Int]
        static func initial() -> State {
            return State(money: 0, stocks: Product.allCases.reduce([Product : Int](), { (result, product) in
                var result = result
                result[product] = 3
                return result
            }))
        }
    }

    // MARK: - UI

    @IBOutlet weak var displayMoney: UILabel!

    @IBOutlet weak var productOut: UIImageView!

    @IBOutlet weak var textInfo: UILabel!

    @IBAction func money100(_ sender: Any) {
        handleProcess("100")
    }

    @IBAction func money500(_ sender: Any) {
        handleProcess("500")
    }

    @IBAction func money1000(_ sender: Any) {
        handleProcess("1000")
    }

    @IBAction func selectCola(_ sender: Any) {
        handleProcess("cola")
    }

    @IBAction func selectCider(_ sender: Any) {
        handleProcess("cider")
    }

    @IBAction func selectFanta(_ sender: Any) {
        handleProcess("fanta")
    }

    @IBAction func reset(_ sender: Any) {
        handleProcess("reset")
    }
    
    @IBAction func add(_ sender: Any) {
        handleProcess("add")
    }

    // MARK: - LOGIC

    lazy var handleProcess = processHandler(State.initial())

    func processHandler(_ initState: State) -> (String) -> Void {
        var state = initState // memoization
        return { command in
            state = self.operation(self.uiInput(command), self.uiOutput)(state)
        }
    }

    func uiInput(_ command: String) -> () -> Input {
        return {
            switch command {
            case "100": return .moneyInput(100)
            case "500": return .moneyInput(500)
            case "1000": return .moneyInput(1000)
            case "cola": return .productSelect(.cola)
            case "cider": return .productSelect(.cider)
            case "fanta": return .productSelect(.fanta)
            case "reset": return .reset
            case "add" : return .addInventory
            default: return .none
            }
        }
    }

    func uiOutput(_ output: Output) -> Void {
        switch output {
        case .displayMoney(let m):
            displayMoney.text = "\(m)"

        case .productOut(let p):
            switch p {
            case .cola:
                productOut.image = #imageLiteral(resourceName: "cola_l")
            case .cider:
                productOut.image = #imageLiteral(resourceName: "cider_l")
            case .fanta:
                productOut.image = #imageLiteral(resourceName: "fanta_l")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.productOut.image = nil
            }

        case .shortMoneyError:
            textInfo.text = "잔액이 부족합니다."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }

        case .change(let c):
            textInfo.text = "\(c)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }
        case .shortStockError(let p):
            textInfo.text = "\(p.name())의 재고가 부족합니다. 재고를 채워주세요."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }
            
        case .displayProductStock(let s):
            textInfo.text = "\(s)개 남았습니다."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }
        }
    }

    func operation(_ inp: @escaping () -> Input, _ out: @escaping (Output) -> Void) -> (State) -> State {
        return { state in
            let input = inp()

            switch input {
            case .moneyInput(let m):
                let money = state.money + m
                out(.displayMoney(money))
                return State(money: money, stocks: state.stocks)

            case .productSelect(let p):
                if state.money < p.rawValue {
                    out(.shortMoneyError)
                    return state
                }
                
                if let stock = state.stocks[p], stock == 0{
                    out(.shortStockError(p))
                    return state
                }
                
                out(.productOut(p))
                let money = state.money - p.rawValue
                out(.displayMoney(money))
                
                var stocks = (state.stocks)
                if stocks[p] != nil  {
                    stocks[p]! -= 1
                    out(.displayProductStock(stocks[p]!))
                }
                
                return State(money: money, stocks: stocks)
                
            case .reset:
                out(.change(state.money))
                out(.displayMoney(0))
                return State(money: 0, stocks: state.stocks)
                
            case .addInventory:
                var stocks = state.stocks
                stocks.forEach({ (product, stock) in
                    if stock == 0 {
                        stocks[product]! = 3
                    }
                })
                return State(money: state.money, stocks: stocks)

            case .none:
                return state
            }
        }
    }

}

