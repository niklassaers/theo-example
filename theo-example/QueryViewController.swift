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
    private var lastNodeId: UInt64 = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableButtons()
        if let config = connectionConfig {
            do {
                self.theo = try BoltClient(
                    hostname: config.host,
                    port: config.port,
                    username: config.username,
                    password: config.password,
                    encrypted: true)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.outputTextView?.text = "Failed during connection configuration"
                }
                return
            }
            
            guard let theo = self.theo else { return }
            
            log("Connecting...")
            
            let result = theo.connectSync()
            switch result {
            case .failure(_):
                log("Error while connecting")
            case .success(_):
                let result = theo.executeCypherSync("MATCH (n:ImpossibleNode) RETURN count(n) AS n")
                switch result {
                case let .failure(error):
                    log("Error while connecting: \(error)")
                case .success(_):
                    log("Connected")
                    DispatchQueue.main.async { [weak self] in
                        self?.enableButtons()
                    }
                }
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
        
        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }
        
        let node = Node(label: "TheoTest", properties:
            ["prop1": "propertyValue_1",
             "prop2": "propertyValue_2"])
        node["prop3"] = "Could add a property this way too"
        node.add(label: "AnotherLabel")
        
        let result = theo.createAndReturnNodeSync(node: node)
        switch result {
        case let .failure(error):
            log("Error while creating node: \(error)")
        case let .success(responseNode):
            log("Successfully created node: \(responseNode)")
            lastNodeId = responseNode.id!
        }
    }
    
    @IBAction func fetchNodeTapped(_ sender: UIButton) {
        
        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }
        
        theo.nodeBy(id: lastNodeId) { result in
            switch result {
            case let .failure(error):
                self.log("Error while reading fetched node with ID '\(self.lastNodeId)': \(error)")
            case let .success(responseNode):
                if let responseNode = responseNode {
                    self.log("Fetched node with ID \(self.lastNodeId): \(responseNode)")
                } else {
                    self.log("Could not find node with ID \(self.lastNodeId)")
                }
            }
        }
    }
    
    func log(_ string: String) {
        print(string)
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
        
        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }

        let result = theo.executeCypherSync("MATCH (n:TheoTest) RETURN count(n) AS num")
        switch result {
        case let .failure(error):
            log("Error while getting cypher results: \(error)")
        case let .success(queryResult):
            if let intNum = queryResult.rows[0]["num"] as? UInt64 {
                log("Asked via Cypher how many nodes there are with label TheoTest. Answer: \(intNum)")
            } else {
                log("Got unexpected answer back")
            }
        }
    }
    
    @IBAction func runTransactionTapped(_ sender: UIButton) {

        do {
            try theo?.executeAsTransaction(transactionBlock: { (tx) in
                let query = "CREATE (n:TheoTest { myProperty: {prop} } )"
                self.theo?.executeCypherSync(query, params: ["prop": "A value"])
                self.theo?.executeCypherSync(query, params: ["prop": "Another value"])
            })
        } catch {
            log("Error while executing transaction: \(error)")
            return
        }
        
        log("Transaction completed successfully")
    }
    
}
