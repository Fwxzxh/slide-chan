import Foundation

#if DEBUG
extension Board {
    static let mock = Board(
        board: "v",
        title: "Video Games",
        ws_board: 1,
        per_page: 15,
        pages: 10,
        meta_description: "Video Games channel on 4chan.",
        max_filesize: 4096,
        max_comment_chars: 2000,
        image_limit: 150,
        cooldowns: nil
    )
}

extension Post {
    static let mock = Post(
        no: 123456789,
        resto: 0,
        time: 1611710000,
        now: "01/27/21(Wed)12:00:00",
        name: "Anonymous",
        sub: "Sample Thread Subject",
        com: "This is a sample comment with some <b>HTML</b> and a <span class=\"quote\">&gt;&gt;12345</span> reply reference. <br> Greentext might look like this:\n>Implying Previews are not useful.",
        filename: "cool_image",
        ext: ".png",
        tim: 1234567890123,
        w: 1920,
        h: 1080,
        tn_w: 250,
        tn_h: 250,
        replies: 42,
        images: 5,
        sticky: nil,
        closed: nil,
        archived: nil,
        trip: nil,
        capcode: nil,
        country: nil,
        country_name: nil,
        filedeleted: nil,
        spoiler: nil,
        custom_spoiler: nil
    )
    
    static let mockReply = Post(
        no: 123456790,
        resto: 123456789,
        time: 1611710500,
        now: "01/27/21(Wed)12:05:00",
        name: "Anonymous",
        sub: nil,
        com: "This is a reply to the previous post.",
        filename: nil,
        ext: nil,
        tim: nil,
        w: nil,
        h: nil,
        tn_w: nil,
        tn_h: nil,
        replies: nil,
        images: nil,
        sticky: nil,
        closed: nil,
        archived: nil,
        trip: nil,
        capcode: nil,
        country: nil,
        country_name: nil,
        filedeleted: nil,
        spoiler: nil,
        custom_spoiler: nil
    )
}

extension ThreadNode {
    static let mock = ThreadNode(
        post: .mock,
        replies: [
            ThreadNode(post: .mockReply)
        ]
    )
}

extension BookmarkedThread {
    static let mock = BookmarkedThread(
        id: "v_123456789",
        board: "v",
        threadId: 123456789,
        subject: "Sample Subject",
        previewText: "This is a preview of the thread content...",
        timestamp: Date()
    )
}
#endif
