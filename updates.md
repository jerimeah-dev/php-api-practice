Update 2:30

1. Fix Replies display, when comments are reloading, it only shows 1 reply when it has many already , handle it properly like comments, with debugprint
2. When there are no post left on home screen show a widget so the user will know

Future

1. When user logs out, clear all state
2. When cant fetch from backend, handle it, -> cant connect to server -> this allows user to know and pull to refresh + no infinite loading on UI
3. Report post on ... button on post card or post detail screen

Was not updated or still not working from previous:
Pull to refresh user profile data in profile screen

=========================

Update 2pm

1. Comment and replies owner can edit and delete their comment
2. all list of posts and comments set limit to 10, initial of 5, each fetch is 5, for each state that manage a list, include a debugprint so we can see the count of items on the list as user scrolls down.

Was not updated from previous:
When revisiting a post/profile, use cached data from state.
Profile screen (User Details, not post list view on profile screen) Pull-to-refresh to update explicitly.
Posts reactions on Profile screen must appear immediately

============================

Needs confirmation from previous:
Each listtile/card(post/comment) rebuild must not rebuild whole listview

===============================

Update: 1:30pm

1. Post Model
   • Add title field for each post.
   • Keep existing fields:
   • id, userId, content, imageUrls, createdAt, updatedAt, reactionCounts, userReaction.

2. UserProfile Model
   • Add coverUrl (list of cover images like avatar).
   • Display logic for cover/avatar:
   1. If coverUrl exists → show it.
   2. Else, fallback to avatarUrl.
   3. Else, show a placeholder colored block.
      • Display logic for name/avatar:
      • If name is empty → first letter of email if available or ?

3. ListTile
   • Each cards of posts or comments manages its own local state
   • Benefit: Only the tile rebuilds, not the entire ListView.

4. Owner-Only Actions
   • Three-dot menu on post card:
   • Visible only if post.userId == currentUser.id.
   • Options: Edit, Delete.

5. Profile Screen & Home ListView
   • Reactions appear immediately via PostTile local state.
   • Avoid unnecessary API calls:
   • When revisiting a post/profile, use cached data from state.
   • Pull-to-refresh to update explicitly.
   • Infinite scroll/pagination continues to work normally:
   • adds new pages without rebuilding all tiles

6. update claude.md lastly, we can say we have set some rules on the update above.
