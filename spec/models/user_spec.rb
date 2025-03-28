# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let!(:me) { FactoryBot.create :user }

  describe "basic assigns" do
    before :each do
      @user = User.new(
        screen_name: "FunnyMeme2004",
        password:    "y_u_no_secure_password?",
        email:       "nice.meme@nsa.gov",
      )
      Profile.new(user: @user)
    end

    subject { @user }

    it { should respond_to(:email) }

    it "#email returns a string" do
      expect(@user.email).to match "nice.meme@nsa.gov"
    end

    it "#motivation_header has a default value" do
      expect(@user.profile.motivation_header).to match ""
    end

    it "does not save an invalid screen name" do
      @user.screen_name = "$Funny-Meme-%&2004"
      expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "callbacks" do
    describe "before_destroy" do
      it "marks reports about this user as deleted" do
        other_user = FactoryBot.create(:user)
        
        UseCase::Report::Create.call(
          reporter_id: other_user.id,
          object_id:   me.screen_name,
          object_type: "User",
          reason:      "va tutto benissimo",
        )

        expect { me.destroy }
          .to change { Reports::User.find_by(target_id: me.id).resolved? }
          .from(false)
          .to(true)
      end
    end

    describe "after_destroy" do
      it "increments the users_destroyed metric" do
        expect { me.destroy }.to change { Retrospring::Metrics::USERS_DESTROYED.values.values.sum }.by(1)
      end
    end

    describe "after_create" do
      subject :user do
        User.create!(
          screen_name: "konqi",
          email:       "konqi@example.rrerr.net",
          password:    "dragonsRQt5",
        )
      end

      it "creates a profile for the user" do
        expect { user }.to change { Profile.count }.by(1)
        expect(Profile.find_by(user:).user).to eq(user)
      end

      it "increments the users_created metric" do
        expect { user }.to change { Retrospring::Metrics::USERS_CREATED.values.values.sum }.by(1)
      end
    end
  end

  describe "custom sharing url validation" do
    subject do
      FactoryBot.build(:user, sharing_custom_url: url).tap(&:validate).errors[:sharing_custom_url]
    end

    shared_examples_for "valid url" do |example_url|
      context "when url is #{example_url}" do
        let(:url) { example_url }

        it "does not have validation errors" do
          expect(subject).to be_empty
        end
      end
    end

    shared_examples_for "invalid url" do |example_url|
      context "when url is #{example_url}" do
        let(:url) { example_url }

        it "has validation errors" do
          expect(subject).not_to be_empty
        end
      end
    end

    include_examples "valid url", "https://myfunnywebsite.com/"
    include_examples "valid url", "https://desu.social/share?text="
    include_examples "valid url", "http://insecurebutvalid.business/"
    include_examples "invalid url", "ftp://fileprotocols.cool/"
    include_examples "invalid url", "notevenanurl"
    include_examples "invalid url", %(https://richtig <strong>oarger</strong> shice) # passes the regexp, but trips up URI.parse
    include_examples "invalid url", %(https://österreich.gv.at) # needs to be ASCII
  end

  describe "email validation" do
    subject do
      FactoryBot.build(:user, email:).tap(&:validate).errors[:email]
    end

    shared_examples_for "valid email" do |example_email|
      context "when email is #{example_email}" do
        let(:email) { example_email }

        it "does not have validation errors" do
          expect(subject).to be_empty
        end
      end
    end

    shared_examples_for "invalid email" do |example_email|
      context "when email is #{example_email}" do
        let(:email) { example_email }

        it "has validation errors" do
          expect(subject).not_to be_empty
        end
      end
    end

    include_examples "valid email", "ifyouusethismailyouarebanned@nilsding.org"
    include_examples "valid email", "fritz.fantom@gmail.com"
    include_examples "valid email", "fritz.fantom@columbiamail.co"
    include_examples "valid email", "fritz.fantom@protonmail.com"
    include_examples "valid email", "fritz.fantom@example.email"
    include_examples "valid email", "fritz.fantom@enterprise.k8s.420stripes.k8s.needs.more.k8s.jira.atlassian.k8s.eu-central-1.s3.amazonaws.com"
    include_examples "valid email", "fritz.fantom@emacs.horse"
    include_examples "invalid email", "@jack"

    # examples from the real world:

    # .carrd is not a valid TLD
    include_examples "invalid email", "fritz.fantom@gmail.carrd"
    # neither is .con
    include_examples "invalid email", "fritz.fantom@gmail.con"
    include_examples "invalid email", "fritz.fantom@protonmail.con"
    # nor .coom
    include_examples "invalid email", "fritz.fantom@gmail.coom"
    # nor .cmo
    include_examples "invalid email", "gustav.geldsack@gmail.cmo"
    # nor .mail (.email is, however)
    include_examples "invalid email", "fritz.fantom@proton.mail"
    # common typos:
    include_examples "invalid email", "fritz.fantom@aoo.com"
    include_examples "invalid email", "fritz.fantom@fmail.com"
    include_examples "invalid email", "fritz.fantom@gamil.com"
    include_examples "invalid email", "fritz.fantom@gemail.com"
    include_examples "invalid email", "fritz.fantom@gmaik.com"
    include_examples "invalid email", "fritz.fantom@gmail.cm"
    include_examples "invalid email", "fritz.fantom@gmail.co"
    include_examples "invalid email", "fritz.fantom@gmail.co.uk"
    include_examples "invalid email", "fritz.fantom@gmail.om"
    include_examples "invalid email", "fritz.fantom@gmailcom"
    include_examples "invalid email", "fritz.fantom@gmaile.com"
    include_examples "invalid email", "fritz.fantom@gmaill.com"
    include_examples "invalid email", "fritz.fantom@gmali.com"
    include_examples "invalid email", "fritz.fantom@gmaul.com"
    include_examples "invalid email", "fritz.fantom@gnail.com"
    include_examples "invalid email", "fritz.fantom@hornail.com"
    include_examples "invalid email", "fritz.fantom@hotamil.com"
    include_examples "invalid email", "fritz.fantom@hotmai.com"
    include_examples "invalid email", "fritz.fantom@hotmailcom"
    include_examples "invalid email", "fritz.fantom@hotmaill.com"
    include_examples "invalid email", "fritz.fantom@iclooud.com"
    include_examples "invalid email", "fritz.fantom@iclould.com"
    include_examples "invalid email", "fritz.fantom@icluod.com"
    include_examples "invalid email", "fritz.fantom@maibox.org"
    include_examples "invalid email", "fritz.fantom@protonail.com"
    include_examples "invalid email", "fritz.fantom@xn--gmail-xk1c.com"
    include_examples "invalid email", "fritz.fantom@yahooo.com"
    include_examples "invalid email", "fritz.fantom@☺gmail.com"
    # gail.com would be a valid email address, but enough people typo it
    #
    # if you're the owner of that TLD and would like to use your email on
    # retrospring, feel free to open a PR that removes this ;-)
    include_examples "invalid email", "fritz.fantom@gail.com"
    # no TLD
    include_examples "invalid email", "fritz.fantom@gmail"
    include_examples "invalid email", "fritz.fantom@protonmail"
  end

  describe "#to_param" do
    subject { me.to_param }

    it { is_expected.to eq me.screen_name }
  end

  # -- User::TimelineMethods --

  shared_examples_for "result is blank" do
    it "result is blank" do
      expect(subject).to be_blank
    end
  end

  describe "#timeline" do
    subject { me.timeline }

    context "user answered nothing and is not following anyone" do
      include_examples "result is blank"
    end

    context "user answered something and is not following anyone" do
      let(:answer) { FactoryBot.create(:answer, user: me) }

      let(:expected) { [answer] }

      it "includes the answer" do
        expect(subject).to eq(expected)
      end
    end

    context "user answered something and follows users with answers" do
      let(:user1) { FactoryBot.create(:user) }
      let(:user2) { FactoryBot.create(:user) }
      let(:answer1) { FactoryBot.create(:answer, user: user1, created_at: 12.hours.ago) }
      let(:answer2) { FactoryBot.create(:answer, user: me, created_at: 1.day.ago) }
      let(:answer3) { FactoryBot.create(:answer, user: user2, created_at: 10.minutes.ago) }
      let(:answer4) { FactoryBot.create(:answer, user: user1, created_at: Time.now.utc) }

      let!(:expected) do
        [answer4, answer3, answer1, answer2]
      end

      before(:each) do
        me.follow(user1)
        me.follow(user2)
      end

      it "includes all answers" do
        expect(subject).to include(answer1)
        expect(subject).to include(answer2)
        expect(subject).to include(answer3)
        expect(subject).to include(answer4)
      end

      it "result is ordered by created_at in reverse order" do
        expect(subject).to eq(expected)
      end
    end

    context "user follows users with answers to questions from blocked or muted users", timeline_test_data: true do
      before do
        me.follow user1
        me.follow user2
      end

      it "includes all answers to questions the user follows" do
        expect(subject).to include(answer_to_anonymous)
        expect(subject).to include(answer_to_normal_user)
        expect(subject).to include(answer_to_normal_user_anonymous)
        expect(subject).to include(answer_to_blocked_user_anonymous)
        expect(subject).to include(answer_to_muted_user_anonymous)
        expect(subject).to include(answer_to_blocked_user)
        expect(subject).to include(answer_to_muted_user)
        expect(subject).not_to include(answer_from_blocked_user)
        expect(subject).not_to include(answer_from_muted_user)
      end

      context "when blocking and muting some users" do
        before do
          me.block blocked_user
          me.mute muted_user
        end

        it "only includes answers to questions from users the user doesn't block or mute" do
          expect(subject).to include(answer_to_anonymous)
          expect(subject).to include(answer_to_normal_user)
          expect(subject).to include(answer_to_normal_user_anonymous)
          expect(subject).to include(answer_to_blocked_user_anonymous)
          expect(subject).to include(answer_to_muted_user_anonymous)
          expect(subject).not_to include(answer_to_blocked_user)
          expect(subject).not_to include(answer_to_muted_user)
          expect(subject).not_to include(answer_from_blocked_user)
          expect(subject).not_to include(answer_from_muted_user)
        end
      end
    end
  end

  describe "#cursored_timeline" do
    let(:last_id) { nil }

    subject { me.cursored_timeline(last_id:, size: 3) }

    context "user answered nothing and is not following anyone" do
      include_examples "result is blank"
    end

    context "user answered something and is not following anyone" do
      let(:answer) { FactoryBot.create(:answer, user: me) }

      let(:expected) { [answer] }

      it "includes the answer" do
        expect(subject).to eq(expected)
      end
    end

    context "user answered something and follows users with answers" do
      let(:user1) { FactoryBot.create(:user) }
      let(:user2) { FactoryBot.create(:user) }
      let!(:answer1) { FactoryBot.create(:answer, user: me, created_at: 1.day.ago) }
      let!(:answer2) { FactoryBot.create(:answer, user: user1, created_at: 12.hours.ago) }
      let!(:answer3) { FactoryBot.create(:answer, user: user2, created_at: 10.minutes.ago) }
      let!(:answer4) { FactoryBot.create(:answer, user: user1, created_at: Time.now.utc) }

      before(:each) do
        me.follow(user1)
        me.follow(user2)
      end

      context "last_id is nil" do
        let(:last_id) { nil }
        let(:expected) do
          [answer4, answer3, answer2]
        end

        it "includes three answers" do
          expect(subject).not_to include(answer1)
          expect(subject).to include(answer2)
          expect(subject).to include(answer3)
          expect(subject).to include(answer4)
        end

        it "result is ordered by created_at in reverse order" do
          expect(subject).to eq(expected)
        end
      end

      context "last_id is answer2.id" do
        let(:last_id) { answer2.id }

        it "includes answer1" do
          expect(subject).to include(answer1)
          expect(subject).not_to include(answer2)
          expect(subject).not_to include(answer3)
          expect(subject).not_to include(answer4)
        end
      end

      context "last_id is answer1.id" do
        let(:last_id) { answer1.id }

        include_examples "result is blank"
      end
    end
  end
end
