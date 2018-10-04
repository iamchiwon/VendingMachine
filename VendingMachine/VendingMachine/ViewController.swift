import UIKit

class ViewController: UIViewController {

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
        case productInput(Product)
        case productSelect(Product)
        case reset
        case none
    }

    enum Output {
        case displayMoney(Int)
        case displayStock(Product, Int)
        case productOut(Product)
        case shortMoneyError
        case shortProductError
        case change(Int)
    }

    struct State {
        let money: Int
        var stocks: [Product: Int]
        
        static func initial() -> State {
            return State(money: 0, stocks: Product.AllCases().reduce([Product: Int](), { result, product in
                var result = result
                result[product] = 0
                return result
            }))
        }
    }

    // MARK: - UI

    @IBOutlet weak var displayMoney: UILabel!

    @IBOutlet weak var productOut: UIImageView!

    @IBOutlet weak var textInfo: UILabel!
    
    @IBOutlet weak var colaStockLabel: UILabel!
    
    @IBOutlet weak var ciderStockLabel: UILabel!
    
    @IBOutlet weak var fantaStockLabel: UILabel!
    
    @IBOutlet weak var saleMode: UISegmentedControl!

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
        if isOnSale() {
            handleProcess("cola")
        } else {
            handleProcess("[in]cola")
        }
    }

    @IBAction func selectCider(_ sender: Any) {
        if isOnSale() {
            handleProcess("cider")
        } else {
            handleProcess("[in]cider")
        }
    }

    @IBAction func selectFanta(_ sender: Any) {
        if isOnSale() {
            handleProcess("fanta")
        } else {
            handleProcess("[in]fanta")
        }
    }

    @IBAction func reset(_ sender: Any) {
        handleProcess("reset")
    }
    
    func isOnSale() -> Bool {
        return saleMode.selectedSegmentIndex == 0
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
            case "[in]cola": return .productInput(.cola)
            case "[in]cider": return .productInput(.cider)
            case "[in]fanta": return .productInput(.fanta)
            case "cola": return .productSelect(.cola)
            case "cider": return .productSelect(.cider)
            case "fanta": return .productSelect(.fanta)
            case "reset": return .reset
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
            
        case .displayStock(let p, let stock):
            switch p {
            case .cola:
                colaStockLabel.text = "\(stock)"
            case .cider:
                ciderStockLabel.text = "\(stock)"
            case .fanta:
                fantaStockLabel.text = "\(stock)"
            }

        case .shortMoneyError:
            textInfo.text = "잔액이 부족합니다."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }
            
        case .shortProductError:
            textInfo.text = "재고가 부족합니다."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.textInfo.text = ""
            }

        case .change(let c):
            textInfo.text = "\(c)"
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
                
            case .productInput(let p):
                var stocks = state.stocks
                stocks[p] = (stocks[p] ?? 0) + 1
                out(.displayStock(p, stocks[p] ?? 0))
                return State(money: state.money, stocks: stocks)

            case .productSelect(let p):
                guard (state.stocks[p] ?? 0) > 0 else {
                    out(.shortProductError)
                    return state
                }
                
                if state.money < p.rawValue {
                    out(.shortMoneyError)
                    return state
                }
                
                out(.productOut(p))
                let money = state.money - p.rawValue
                out(.displayMoney(money))
                
                var stocks = state.stocks
                if let productStock = stocks[p] {
                    stocks[p] = productStock - 1
                    out(.displayStock(p, productStock - 1))
                } else {
                    stocks[p] = 0
                    out(.displayStock(p, 0))
                }

                return State(money: money, stocks: stocks)

            case .reset:
                out(.change(state.money))
                out(.displayMoney(0))
                return State(money: 0, stocks: state.stocks)

            case .none:
                return state
            }
        }
    }

}

