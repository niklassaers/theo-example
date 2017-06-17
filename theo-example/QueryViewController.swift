import UIKit
import Theo
import PackStream

class QueryViewController: UIViewController {

    var connectionConfig: ConnectionConfig?
    @IBOutlet weak var outputTextView: UITextView?
    
    @IBOutlet weak var createNodeButton: UIButton?
    @IBOutlet weak var fetchNodeButton: UIButton?
    @IBOutlet weak var runCypherButton: UIButton?
    @IBOutlet weak var runTransactionButton: UIButton?
    
    
    private var theo: BoltClient?
    private var lastNodeId = "1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableButtons()
        if let config = connectionConfig {
            do {
            theo = try  BoltClient(hostname: config.host, port: config.port, username: config.username, password: config.password, encrypted: true)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.outputTextView?.text = "Failed during connection configuration"
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.outputTextView?.text = "Connecting..."
            }
            
            do {
                let group = DispatchGroup()
                group.enter()
                try theo?.connect() { (success) in
                    if success == false {
                        self.outputTextView?.text = "Error while connecting"
                    }
                    group.leave()
                }
                group.wait()

                group.enter()
                _ = try theo?.executeCypher("MATCH (n:ImpossibleNode) RETURN count(n) AS n", params: nil) { (result) in
                    DispatchQueue.main.async { [weak self] in
                        if result == false {
                            self?.outputTextView?.text = "Error while connecting"
                        } else {
                            self?.outputTextView?.text = "Connected"
                            self?.enableButtons()
                        }
                    }
                    group.leave()
                }
                group.wait()
                
                group.enter()
                try theo?.pullAll { (_, _) in // remember to get result
                    group.leave()
                }
                group.wait()
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.outputTextView?.text = "Error while connecting: \(error)"
                }
                return
            }

        } else {
            outputTextView?.text = "Missing connection configuration"
        }

    }

    private func enableButtons() {
        createNodeButton?.isEnabled = true
        fetchNodeButton?.isEnabled = true
        runCypherButton?.isEnabled = true
        runTransactionButton?.isEnabled = true
    }
    
    private func disableButtons() {
        createNodeButton?.isEnabled = false
        fetchNodeButton?.isEnabled = false
        runCypherButton?.isEnabled = false
        runTransactionButton?.isEnabled = false
    }
    
    @IBAction func createNodeTapped(_ sender: UIButton) {
        
        let query = "CREATE (n:TheoTest:OtherLabel { propertyKey_1: {prop1}, propertyKey_2: {prop2} }) RETURN n,ID(n)"
        let params = ["prop1": "propertyValue_1", "prop2": "propertyValue_2"]
        
        do {
            try theo?.executeCypher(query, params: params) { result in
                do {
                    try theo?.pullAll { (success, response) in
                        if success == false || response.count != 2 {
                            return
                        }
                        
                        if let responseList = response[0].items[0] as? List,
                            responseList.items.count == 2,
                            let responseNode = responseList.items[0] as? Structure,
                            let responseNodeId = Int(responseList.items[1]) {
                                lastNodeId = "\(responseNodeId)"
                                log("\(responseNode)")
                        }
                    }
                } catch {
                    log("Error while creating node: \(error)")
                }
            }
        } catch {
            log("Error while creating node: \(error)")
        }
    }
    
    @IBAction func fetchNodeTapped(_ sender: UIButton) {
        
        let nodeId = lastNodeId
        let query = "MATCH (n) WHERE ID(n) = \(nodeId) RETURN n"

        do {
            try theo?.executeCypher(query, params: nil) { result in
                do {
                    try theo?.pullAll { (success, response) in
                        if success == false || response.count != 2 {
                            return
                        }
                        
                        if let responseList = response[0].items[0] as? List,
                            responseList.items.count == 1,
                            let responseNode = responseList.items[0] as? Structure {

                            log("Fetched node with ID \(nodeId): \(responseNode)")
                        }
                    }
                } catch {
                    log("Error while reading fetched node with ID '\(nodeId)': \(error)")
                }
            }
        } catch {
            log("Error while fetching node with ID '\(nodeId)': \(error)")
        }
    }
    
    func log(_ string: String) {
        DispatchQueue.main.async {
            let text = self.outputTextView?.text ?? ""
            if text == "" {
                self.outputTextView?.text = string
            } else {
                self.outputTextView?.text = "\(string)\n\n\(text)"
            }
        }
    }
    
    @IBAction func runCypherTapped(_ sender: UIButton) {
        do {
            try theo?.executeCypher("MATCH (n:TheoTest) RETURN count(n) AS num", params: nil) { (success) in
                do {
                    try theo?.pullAll { (success, results) in
                        if success == false {
                            log("Error while getting cypher results")
                            return
                        }
                        
                        for result in results {
                            if let resultList = result.items.first as? List,
                               let num = resultList.items.first,
                               let intNum = Int(num) {
                                log("Asked via Cypher how many nodes there are with label TheoTest. Answer: \(intNum)")
                            } else {
                                log("Got unexpected answer back")
                            }
                        }
                    }
                } catch {
                    log("Error while getting cypher results: \(error)")
                }
            }
        } catch {
            log("Error while executing cypher: \(error)")
        }
    }
    
    @IBAction func runTransactionTapped(_ sender: UIButton) {
        
        /*
        let statement1 = [
            "statement" : "CREATE (n:TheoTest { myProperty: 'A value' } )" as AnyObject,
            "resultDataContents" : ["graph","row"] as AnyObject
        ]
        let statement2 = [
            "statement" : "CREATE (m:TheoTest { myProperty: 'Another value' } )" as AnyObject,
            "resultDataContents" : ["graph","row"] as AnyObject
        ]
        
        theo?.executeTransaction([statement1, statement2]) { (result, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while executing transaction: \(error)\n\n\(text)"
                } else {
                    self?.outputTextView?.text = "Transaction completed successfully\n\n\(text)"
                }
            }
        }
        */
    }
    
}
