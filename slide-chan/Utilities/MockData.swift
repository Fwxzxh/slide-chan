import Foundation

#if DEBUG
/// Collection of mock data used for SwiftUI previews and unit testing.
extension Board {
    /// A standard mock board representing /v/ - Video Games.
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
    /// A standard Original Post (OP) with an image and subject.
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
        sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
        country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
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
        sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
        country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
    )
    
    static let mockManyStats = Post(
        no: 123456791,
        resto: 0,
        time: 1611710000,
        now: "01/27/21(Wed)12:00:00",
        name: "Anonymous",
        sub: "Thread with many stats",
        com: "This thread has a lot of engagement.",
        filename: "test",
        ext: ".png",
        tim: 1234567890123,
        w: 1920,
        h: 1080,
        tn_w: 250,
        tn_h: 250,
        replies: 999,
        images: 450,
        sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
        country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
    )
    
    static let mockLongTitle = Post(
        no: 123456792,
        resto: 0,
        time: 1611710000,
        now: "01/27/21(Wed)12:00:00",
        name: "Anonymous",
        sub: "This is an extremely long thread subject that should definitely wrap to at least two lines in the row view to test how it handles space",
        com: "Snippet of the post content...",
        filename: nil,
        ext: nil,
        tim: nil,
        w: nil,
        h: nil,
        tn_w: nil,
        tn_h: nil,
        replies: 10,
        images: 0,
        sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
        country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
    )
    
    static let mockNoSubject = Post(
        no: 123456793,
        resto: 0,
        time: 1611710000,
        now: "01/27/21(Wed)12:00:00",
        name: "Anonymous",
        sub: nil,
        com: "This post has no subject, only a comment. We need to make sure the row still looks good and balanced without the bold title.",
        filename: "image",
        ext: ".jpg",
        tim: 1234567890124,
        w: 800,
        h: 600,
        tn_w: 200,
        tn_h: 150,
        replies: 5,
        images: 1,
        sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
        country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
    )
}

extension ThreadNode {
    /// A small thread with one reply.
    static let mock = ThreadNode(
        post: .mock,
        replies: [
            ThreadNode(post: .mockReply)
        ]
    )
    
    /// A mock reply demonstrating greentext rendering.
    static let mockGreentext = ThreadNode(
        post: Post(
            no: 123456794,
            resto: 123456789,
            time: 1611710500,
            now: "01/27/21(Wed)12:05:00",
            name: "Anonymous",
            sub: nil,
            com: ">Implying this is a real reply\nJust seething and coping.",
            filename: nil,
            ext: nil,
            tim: nil,
            w: nil,
            h: nil,
            tn_w: nil,
            tn_h: nil,
            replies: nil,
            images: nil,
            sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
            country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
        )
    )
    
    static let mockLongFile = ThreadNode(
        post: Post(
            no: 123456795,
            resto: 123456789,
            time: 1611710500,
            now: "01/27/21(Wed)12:05:00",
            name: "Anonymous",
            sub: nil,
            com: "Check out this file.",
            filename: "extremely_long_filename_that_should_truncate_properly_in_the_ui_layout",
            ext: ".png",
            tim: 1234567890125,
            w: 100,
            h: 100,
            tn_w: 100,
            tn_h: 100,
            replies: nil,
            images: nil,
            sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
            country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
        )
    )
    
    static let mockShort = ThreadNode(
        post: Post(
            no: 123456796,
            resto: 123456789,
            time: 1611710500,
            now: "01/27/21(Wed)12:05:00",
            name: "Anonymous",
            sub: nil,
            com: "Meds.",
            filename: nil,
            ext: nil,
            tim: nil,
            w: nil,
            h: nil,
            tn_w: nil,
            tn_h: nil,
            replies: nil,
            images: nil,
            sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
            country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
        )
    )
    
    static let mockLong = ThreadNode(
        post: .mock,
        replies: [
            ThreadNode(post: .mockReply),
            ThreadNode(post: Post(
                no: 123456801,
                resto: 123456789,
                time: 1611710600,
                now: "01/27/21(Wed)12:06:00",
                name: "Anonymous",
                sub: nil,
                com: "This is a reply with an image attached.",
                filename: "landscape",
                ext: ".jpg",
                tim: 1234567890126,
                w: 1200,
                h: 800,
                tn_w: 250,
                tn_h: 160,
                replies: nil,
                images: nil,
                sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
            )),
            ThreadNode(post: Post(
                no: 123456802,
                resto: 123456789,
                time: 1611710700,
                now: "01/27/21(Wed)12:07:00",
                name: "Anonymous",
                sub: nil,
                com: ">Be me\n>Enjoying slide-chan\n>The UI is finally consistent.",
                filename: nil,
                ext: nil,
                tim: nil,
                w: nil,
                h: nil,
                tn_w: nil,
                tn_h: nil,
                replies: nil,
                images: nil,
                sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
            )),
            ThreadNode(post: Post(
                no: 123456803,
                resto: 123456789,
                time: 1611710800,
                now: "01/27/21(Wed)12:08:00",
                name: "Anonymous",
                sub: nil,
                com: "Another short comment.",
                filename: "portrait",
                ext: ".png",
                tim: 1234567890127,
                w: 800,
                h: 1200,
                tn_w: 160,
                tn_h: 250,
                replies: 2,
                images: nil,
                sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
            ), replies: [
                ThreadNode(post: Post(
                    no: 123456804,
                    resto: 123456803,
                    time: 1611710900,
                    now: "01/27/21(Wed)12:09:00",
                    name: "Anonymous",
                    sub: nil,
                    com: "Deeply nested reply test.",
                    filename: nil,
                    ext: nil,
                    tim: nil,
                    w: nil,
                    h: nil,
                    tn_w: nil,
                    tn_h: nil,
                    replies: nil,
                    images: nil,
                    sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                    country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
                ))
            ]),
            ThreadNode(post: Post(
                no: 123456805,
                resto: 123456789,
                time: 1611711000,
                now: "01/27/21(Wed)12:10:00",
                name: "Anonymous",
                sub: nil,
                com: "The end of the mock thread.",
                filename: nil,
                ext: nil,
                tim: nil,
                w: nil,
                h: nil,
                tn_w: nil,
                tn_h: nil,
                replies: nil,
                images: nil,
                sticky: nil, closed: nil, archived: nil, trip: nil, capcode: nil,
                country: nil, country_name: nil, filedeleted: nil, spoiler: nil, custom_spoiler: nil
            ))
        ]
    )
}

extension BookmarkedThread {
    /// A sample bookmarked thread for list previews.
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
