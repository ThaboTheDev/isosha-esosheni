import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/signed_url_cache.dart';
import 'package:isosha_esosheni/data/backend/fake_backend.dart';
import 'package:isosha_esosheni/data/repositories/account_repo.dart';
import 'package:isosha_esosheni/data/repositories/community_repo.dart';
import 'package:isosha_esosheni/data/repositories/conferences_repo.dart';
import 'package:isosha_esosheni/data/repositories/consult_repo.dart';
import 'package:isosha_esosheni/data/repositories/discovery_repo.dart';
import 'package:isosha_esosheni/data/repositories/households_repo.dart';
import 'package:isosha_esosheni/data/repositories/messaging_repo.dart';
import 'package:isosha_esosheni/data/repositories/relationships_repo.dart';
import 'package:isosha_esosheni/data/repositories/safety_repo.dart';

import 'recording_backend.dart';

void main() {
  late RecordingBackend b;

  setUp(() => b = RecordingBackend(FakeBackendForTests()));

  test('discovery RPC parameter names', () async {
    final repo = DiscoveryRepository(b);
    await repo.recommendations(lim: 3, off: 0);
    expect(b.paramKeys('get_recommendations'), ['lim,off']);

    await repo.search({'province': 'Gauteng'}, page: 1);
    expect(b.paramKeys('search_members'), ['f,page']);

    await repo.memberProfile('u-1');
    expect(b.paramKeys('get_member_profile_guarded'), ['target']);

    await repo.compatibility('u-1');
    expect(b.paramKeys('get_compatibility'), ['c']);

    await repo.sendInterest('u-1', note: 'Hello');
    expect(b.paramKeys('send_interest'), ['note,target']);

    await repo.respondInterest('i-2', true);
    expect(b.paramKeys('respond_interest'), ['accept,interest']);

    await repo.withdrawInterest('i-2');
    expect(b.paramKeys('withdraw_interest'), ['interest']);

    await repo.toggleLike('u-1');
    expect(b.paramKeys('toggle_like'), ['target']);

    await repo.toggleSave('u-1');
    expect(b.paramKeys('toggle_save'), ['target']);

    await repo.setPass('u-1', true);
    expect(b.paramKeys('set_pass'), ['passed,target']);

    await repo.endMatch('u-1');
    expect(b.paramKeys('end_match'), ['match']);

    await repo.reportMember('u-1', 'spam', 'details', conv: 'c-1', msg: 'm-1');
    expect(b.paramKeys('report_member'),
        ['category,conv,details,msg,target']);
  });

  test('messaging RPC parameter names', () async {
    final repo = MessagingRepository(b, SignedUrlCache(b));
    await repo.conversation('c-1');
    expect(b.paramKeys('get_conversation'), ['conv']);

    await repo.sendText('c-1', 'hi');
    expect(b.paramKeys('send_message').first, 'body,conv,kind');

    await repo.markRead('c-1');
    expect(b.paramKeys('mark_conversation_read'), ['conv']);

    await repo.react('m-1', '🙏');
    expect(b.paramKeys('react_message'), ['emoji,msg']);

    await repo.deleteMessage('m-1');
    expect(b.paramKeys('delete_message'), ['msg']);
  });

  test('relationship + consultation parameter names', () async {
    final repo = RelationshipsRepository(b);
    await repo.proposeStage('r-1',
        note: 'n',
        marriageDate: '2026-12-01',
        marriageType: 'civil',
        marriageDetails: 'd');
    expect(b.paramKeys('propose_stage'), [
      'marriage_date,marriage_details,marriage_type,note,rel_id',
    ]);

    await repo.respondProposal('p-1', false, note: 'Not yet');
    expect(b.paramKeys('respond_stage_proposal'), ['accept,note,prop']);

    await repo.pause('r-1', reason: 'time');
    expect(b.paramKeys('pause_relationship'), ['reason,rel_id']);

    await repo.resume('r-1');
    expect(b.paramKeys('resume_relationship'), ['rel_id']);

    await repo.requestConsultation('r-1',
        mode: 'video', availability: 'weekends', note: 'n');
    expect(b.paramKeys('request_consultation'),
        ['availability,mode,note,rel_id']);

    await repo.respondConsultation('cr-1', true);
    expect(b.paramKeys('respond_consultation'), ['accept,req']);

    await repo.requestReschedule('s-1', 'please');
    expect(b.paramKeys('request_reschedule'), ['note,sess']);
  });

  test('household parameter names', () async {
    final repo = HouseholdsRepository(b);
    await repo.saveHousehold(
      about: 'a',
      seeking: 's',
      children: 2,
      province: 'Gauteng',
      city: 'Johannesburg',
    );
    expect(b.paramKeys('save_household'),
        ['about,children,city,province,seeking']);

    await repo.respondConsent('h-1', true, note: 'n');
    expect(b.paramKeys('respond_household_consent'), ['give,hh,note']);

    await repo.closeHousehold('h-1', reason: 'r');
    expect(b.paramKeys('close_household'), ['hh,reason']);

    await repo.sendInterest('u-3', note: 'hello');
    expect(b.paramKeys('send_household_interest'), ['note,target']);
  });

  test('community parameter names', () async {
    final repo = CommunityRepository(b, SignedUrlCache(b));
    await repo.createPost('body', mediaPath: 'me/1.jpg');
    expect(b.paramKeys('create_post'), ['body,media']);

    await repo.addComment('p-1', 'kind');
    expect(b.paramKeys('add_comment'), ['body,post']);

    await repo.reactPost('p-1', null);
    expect(b.paramKeys('react_post'), ['post']);

    await repo.createStory('blessing', 'royal', mediaPath: 'me/2.jpg');
    expect(b.paramKeys('create_story'), ['background,body,media']);

    await repo.reportContent('post', 'p-1', 'spam', 'details');
    expect(b.paramKeys('report_content'), ['category,details,item,kind']);

    await repo.feed(before: '2026-01-01T00:00:00Z', lim: 20);
    expect(b.paramKeys('get_feed'), ['before,lim']);
  });

  test('conference parameter names', () async {
    final repo = ConferencesRepository(b);
    await repo.detail('conf-1');
    expect(b.paramKeys('conference_detail'), ['conf']);

    await repo.register('conf-1');
    expect(b.paramKeys('register_conference'), ['conf']);

    await repo.askQuestion('sess-1', 'question', anonymous: true);
    expect(b.paramKeys('ask_question'), ['anonymous,body,session']);

    await repo.liveRoom('sess-1');
    expect(b.paramKeys('live_room'), ['session']);

    await repo.sendLiveChat('sess-1', 'hello');
    expect(b.paramKeys('send_live_chat'), ['body,session']);

    await repo.goLive('sess-1', 'youtube', url: 'https://youtu.be/x');
    expect(b.paramKeys('go_live'), ['kind,session,url']);

    await repo.endLive('sess-1', recording: 'https://youtu.be/y');
    expect(b.paramKeys('end_live'), ['recording,session']);
  });

  test('safety + account parameter names', () async {
    final safety = SafetyRepository(b);
    await safety.submitAppeal('s-1', 'statement');
    expect(b.paramKeys('submit_appeal'), ['sanction,statement']);

    final account = AccountRepository(b, SignedUrlCache(b));
    await account.updateProfile('u-me', {
      'bio_about': 'x' * 50,
      'account_status': 'hacked', // protected: must be stripped
    });
    final call = b.calls.firstWhere((c) => c.fn == 'update');
    expect(call.params!.containsKey('account_status'), isFalse);
  });

  test('consultant parameter names', () async {
    final repo = ConsultRepository(b);
    await repo.scheduleSession('r-1',
        at: '2026-10-10T10:00:00Z',
        minutes: 60,
        mode: 'in_person',
        location: 'room');
    expect(b.paramKeys('schedule_session'),
        ['at,location,minutes,mode,req']);

    await repo.recordOutcome('r-1', 'approved', 'summary');
    expect(b.paramKeys('record_outcome'), ['req,result,summary']);

    await repo.reviewHousehold('h-1', true, 'note');
    expect(b.paramKeys('review_household'), ['approve,hh,note']);

    await repo.handBack('r-1', 'reason', toSuper: true);
    expect(b.paramKeys('hand_back_consultation'), ['reason,req,to_super']);
  });
}

class FakeBackendForTests extends FakeBackend {}
