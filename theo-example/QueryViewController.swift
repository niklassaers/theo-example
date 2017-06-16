import UIKit
import Theo

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

                _ = try theo?.executeCypher("MATCH (n:ImpossibleNode) RETURN count(n)", params: nil) { (result) in
                    DispatchQueue.main.async { [weak self] in
                        if result == false {
                            self?.outputTextView?.text = "Error while connecting"
                        } else {
                            self?.outputTextView?.text = "Connected"
                            self?.enableButtons()
                        }
                    }
                }
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
        var node = Node()
        let randomString: String = UUID().uuidString
        
        let query = "CREATE (n:TheoTest { propertyKey_1: {prop1}, propertyKey_2: {prop2} } RETURN n"
        let params = ["prop1": "propertyValue_1", "prop2": "propertyValue_2"]
        
        do {
            try theo?.executeCypher(query, params: params) { result in
                var text = self.outputTextView?.text ?? ""
                do {
                    try theo?.pullAll { (success, response) in
                        text.append(response.description)
                        text.append("\n")
                    }
                } catch {
                    self.outputTextView?.text = "Error while creating node: \(error)\n\n\(text)"
                }
            }
        } catch {
            let text = self.outputTextView?.text ?? ""
            self.outputTextView?.text = "Error while creating node: \(error)\n\n\(text)"
        }
    }
    
    @IBAction func fetchNodeTapped(_ sender: UIButton) {
        /*
        let fetchingId = lastNodeId
        theo?.fetchNode(fetchingId, completionBlock: { (node, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while fetching node with ID '\(fetchingId)': \(error)\n\n\(text)"
                } else {
                    self?.outputTextView?.text = "Fetched node with ID \(node?.meta?.nodeID() ?? "N/A") successfully\n\n\(text)"
                }
            }
        })
        */
    }
    
    @IBAction func runCypherTapped(_ sender: UIButton) {
        do {
            try theo?.executeCypher("MATCH (n:TheoTest) RETURN count(n) AS num", params: nil) { (success) in
                do {
                    try theo?.pullAll { (success, results) in
                        if success == false {
                            DispatchQueue.main.async {
                                let text = self.outputTextView?.text ?? ""
                                self.outputTextView?.text = "Error while getting cypher results\n\n\(text)"
                            }
                        }
                        for result in results {
                            let num = result.items.first as? Int
                            DispatchQueue.main.async {
                                let text = self.outputTextView?.text ?? ""
                                self.outputTextView?.text = "Asked via Cypher how many nodes there are with label TheoTest. Answer: \(num)\n\n\(text)"
                            }
                            
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        let text = self.outputTextView?.text ?? ""
                        self.outputTextView?.text = "Error while getting cypher results: \(error)\n\n\(text)"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                let text = self.outputTextView?.text ?? ""
                self.outputTextView?.text = "Error while executing cypher: \(error)\n\n\(text)"
            }
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
