import Foundation

struct MailSource: Identifiable, Codable, Equatable {
    var id = UUID()
    var emailAddress = ""
    var imapHost = "imap.mail.me.com"
    var imapPort = 993
    var useSSL = true
    var syncDays = 30
    var createdAt = Date()
    var updatedAt = Date()
}

