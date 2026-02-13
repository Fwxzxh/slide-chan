import Testing
import Foundation
@testable import slide_chan

struct PostLogicTests {

    @Test func testCleanComment() {
        let post = Post(
            no: 1,
            resto: 0,
            time: nil,
            now: nil,
            name: nil,
            sub: nil,
            com: "Hello<br>World <span class=\"quote\">&gt;&gt;123</span> &amp; more",
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
        
        #expect(post.cleanComment == "Hello\nWorld >>123 & more")
    }
    
    @Test func testReplyIds() {
        let post = Post(
            no: 2,
            resto: 1,
            time: nil,
            now: nil,
            name: nil,
            sub: nil,
            com: ">>123456\n&gt;&gt;789012\nSome text",
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
        
        let ids = post.replyIds()
        #expect(ids == [123456, 789012])
    }
}
