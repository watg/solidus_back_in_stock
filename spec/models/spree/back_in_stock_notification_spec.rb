RSpec.describe Spree::BackInStockNotification do

  describe "#create" do
    subject { back_in_stock_notification.save! }
    let(:back_in_stock_notification) { build(:back_in_stock_notification) }

    context "with valid params" do

      it "saves the record" do
        expect{ subject }
          .to change { described_class.count }
          .from(0).to(1)
      end

      context "when no product_id is given" do
        let!(:variant) { create(:variant) }
        let(:back_in_stock_notification) { build(:back_in_stock_notification, variant: variant) }
        before { back_in_stock_notification.product_id = nil }

        it "sets the product_id to the variant product_id" do
          subject
          back_in_stock_notification.reload
          expect( back_in_stock_notification.product_id ).to eq variant.product_id
        end
      end

      context "when no product_id is given" do
        let!(:variant) { create(:variant) }
        let!(:product) { create(:product) }
        let(:back_in_stock_notification) { build(:back_in_stock_notification, variant: variant) }
        before { back_in_stock_notification.product_id = product.id }

        it "sets the product_id to the variant product_id" do
          subject
          back_in_stock_notification.reload
          expect( variant.product_id ).to_not eq product.id
          expect( back_in_stock_notification.product_id ).to eq product.id
        end
      end
    end

    context "when the email is missing" do
      before { back_in_stock_notification.email = nil }

      it "does not save record" do
        expect{ subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the email is invalid" do
      before { back_in_stock_notification.email = "inavalid.email" }

      it "does not save record" do
        expect{ subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "a record already with the same email and variant" do
      let(:existing_back_in_stock_notification) { create(:back_in_stock_notification) }
      let(:back_in_stock_notification) { build(:back_in_stock_notification) }
      before do
        back_in_stock_notification.email = existing_back_in_stock_notification.email_sent_at
        back_in_stock_notification.variant_id = existing_back_in_stock_notification.variant_id
      end

      it "does not save record" do
        expect{ subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".pending" do
    subject { Spree::BackInStockNotification.pending }
    let!(:back_in_stock_notification) { create(:back_in_stock_notification, email_sent_at: email_sent_at) }

    context "email has not been sent" do
      let(:email_sent_at) { nil }

      it "returns one result" do
        expect(subject).to eq [back_in_stock_notification]
      end
    end

    context "email already sent" do
      let(:email_sent_at) { 1.hour.ago }

      it "returns nothing" do
        expect(subject).to eq []
      end
    end
  end

  describe ".in_stock" do
    subject { described_class.in_stock(stock_location) }
    let!(:back_in_stock_notification) { create(:back_in_stock_notification) }
    let!(:variant) { back_in_stock_notification.variant }
    let!(:stock_location) { variant.stock_items.first.stock_location }
    before do
      back_in_stock_notification.update_column :stock_location_id, stock_location.id
    end

    context "is not backorderable and inventory is tracked" do
      let(:backorderable) { false }

      context "item is in stock" do
        before { variant.stock_items.update_all count_on_hand: 50, backorderable: backorderable }

        context "the product is available" do
          before { variant.product.update available_on: 1.day.ago }

          it "returns one result" do
            expect(subject).to eq [back_in_stock_notification]
          end

          context "the product abailable_on date is in the future" do
            before { variant.product.update available_on: 1.day.from_now }

            it { is_expected.to eq [] }
          end
        end

        context "the product abailable_on date is not set" do
          before { variant.product.update available_on: 1.day.from_now }

          it { is_expected.to eq [] }
        end
      end

      context "item is out of stock" do
        before { variant.stock_items.update_all count_on_hand: 0, backorderable: backorderable }

        it { is_expected.to eq [] }
      end
    end

    context "the product is available" do
      before { variant.product.update available_on: 1.day.ago }

      context "is backorderable" do
        let(:backorderable) { true }

        context "item is out of stock" do
          before { variant.stock_items.update_all count_on_hand: 0, backorderable: backorderable }

          it "returns one result" do
            expect(subject).to eq [back_in_stock_notification]
          end
        end
      end

      context "inventory is not tracked and is not backorderable" do
        let(:backorderable) { false }

        before { variant.update track_inventory: false }

        context "item is out of stock" do
          before { variant.stock_items.update_all count_on_hand: 0, backorderable: backorderable }

          it "returns one result" do
            expect(subject).to eq [back_in_stock_notification]
          end
        end
      end
    end
  end

  describe "#stock_count" do
    subject { back_in_stock_notification.stock_count }
    let!(:back_in_stock_notification) { create(:back_in_stock_notification) }
    let!(:variant) { back_in_stock_notification.variant }

    context "is not backorderable" do
      let(:backorderable) { false }

      context "count on hand is 7" do
        before do
          variant.stock_items.update_all count_on_hand: 7, backorderable: backorderable
        end

        it { is_expected.to eq 7 }
      end
    end

    context "it is backorderable" do
      let(:backorderable) { true }

      it { is_expected.to eq '∞' }
    end
  end

  describe "#pending?" do
    subject { back_in_stock_notification.pending? }
    let!(:back_in_stock_notification) { create(:back_in_stock_notification, email_sent_at: email_sent_at) }

    context "email has not been sent" do
      let(:email_sent_at) { nil }

      it { is_expected.to eq true }
    end

    context "email has been sent" do
      let(:email_sent_at) { 1.day.ago }

      it { is_expected.to eq false }
    end
  end

  describe ".emails_of_ready_to_send" do
    subject { described_class.emails_of_ready_to_send(stock_location) }

    context "when there are no pending notifications" do
      let!(:bisn) { create(:back_in_stock_notification, email_sent_at: 1.hour.ago) }
      let(:stock_location) { bisn.variant.stock_items.first.stock_location }

      it { is_expected.to eq([]) }
    end

    context "with two pending notifications in different stock locations" do
      let(:email_1) { "email_1@domain.com" }
      let(:email_2) { "email_2@domain.com" }

      let!(:stock_location_1) { create(:stock_location) }
      let!(:stock_location_2) { create(:stock_location) }

      let!(:variant_1) { create(:variant) }
      let!(:variant_2) { create(:variant) }

      let!(:stock_item_1) do
        variant_1.stock_items.find_by(stock_location: stock_location_1) ||
        create(:stock_item, variant: variant_1, stock_location: stock_location_1)
      end
      let!(:stock_item_2) do
        variant_2.stock_items.find_by(stock_location: stock_location_2) ||
        create(:stock_item, variant: variant_2, stock_location: stock_location_2)
      end

      let!(:bisn_1) do
        create(:back_in_stock_notification,
          email: email_1,
          variant: variant_1,
          stock_location: stock_location_1)
      end

      let!(:bisn_2) do
        create(:back_in_stock_notification,
          email: email_2,
          variant: variant_2,
          stock_location: stock_location_2)
      end

      context "request for location 1" do
        let(:stock_location) { stock_location_1 }

        context "variant is in stock" do
          before do
            stock_item_1.update_columns(
              count_on_hand: 10,
              backorderable: false,
              stock_location_id: stock_location_1.id
            )
          end

          it { is_expected.to eq [email_1] }
        end

        context "variant is out of stock" do
          before do
            stock_item_1.update_columns(
              count_on_hand: 0,
              backorderable: false,
              stock_location_id: stock_location_1.id
            )
          end

          it { is_expected.to eq [] }
        end
      end

      context "request for location 2" do
        let(:stock_location) { stock_location_2 }

        context "variant is in stock" do
          before do
            stock_item_2.update_columns(
              count_on_hand: 10,
              backorderable: false,
              stock_location_id: stock_location_2.id
            )
          end

          it { is_expected.to eq [email_2] }
        end

        context "variant is out of stock" do
          before do
            stock_item_2.update_columns(
              count_on_hand: 0,
              backorderable: false,
              stock_location_id: stock_location_2.id
            )
          end

          it { is_expected.to eq [] }
        end
      end
    end
  end

  describe ".ready_to_send_by_email" do
    subject { described_class.ready_to_send_by_email(email, stock_location) }
    let!(:variant_1) { create(:variant) }
    let!(:variant_2) { create(:variant) }

    context "two pending stock notifications" do
      let!(:bisn_1) do
        create(:back_in_stock_notification,
          email: email_1,
          variant: variant_1,
          stock_location: stock_location_1)
      end

      let!(:bisn_2) do
        create(:back_in_stock_notification,
          email: email_2,
          variant: variant_2,
          stock_location: stock_location_2)
      end

      context "both with matching email and stock location" do
        let(:email) { "user@email.com" }
        let(:email_1) { email }
        let(:email_2) { email }
        let!(:stock_location) { create(:stock_location) }
        let!(:stock_location_1) { stock_location }
        let!(:stock_location_2) { stock_location }

        let!(:stock_item_1) do
          variant_1.stock_items.find_by(stock_location: stock_location_1) ||
          create(:stock_item, variant: variant_1, stock_location: stock_location_1)
        end
        let!(:stock_item_2) do
          variant_2.stock_items.find_by(stock_location: stock_location_2) ||
          create(:stock_item, variant: variant_2, stock_location: stock_location_2)
        end

        it "returns both the notifications" do
          expect( subject.map(&:id) ).to match_array([bisn_1.id, bisn_2.id])
        end
      end

      context "when one has a different email but same stock location" do
        let(:email) { "user_1@email.com" }
        let(:email_1) { email }
        let(:email_2) { "user_2@email.com" }
        let!(:stock_location) { create(:stock_location) }
        let!(:stock_location_1) { stock_location }
        let!(:stock_location_2) { stock_location }

        let!(:stock_item_1) do
          variant_1.stock_items.find_by(stock_location: stock_location_1) ||
          create(:stock_item, variant: variant_1, stock_location: stock_location_1)
        end
        let!(:stock_item_2) do
          variant_2.stock_items.find_by(stock_location: stock_location_2) ||
          create(:stock_item, variant: variant_2, stock_location: stock_location_2)
        end

        it "returns the expected notification" do
          expect( subject.map(&:id) ).to eq [bisn_1.id]
        end
      end

      context "when one has a different stock location but same email" do
        # Just for consistency - usually people would not request from separate stock
        # locations but it is awkward to bundle them together. This test just confirms
        # that they are handled separately
        let(:email) { "user@email.com" }
        let(:email_1) { email }
        let(:email_2) { email }
        let!(:stock_location) { create(:stock_location) }
        let!(:stock_location_1) { stock_location }
        let!(:stock_location_2) { create(:stock_location) }

        let!(:stock_item_1) do
          variant_1.stock_items.find_by(stock_location: stock_location_1) ||
          create(:stock_item, variant: variant_1, stock_location: stock_location_1)
        end
        let!(:stock_item_2) do
          variant_2.stock_items.find_by(stock_location: stock_location_2) ||
          create(:stock_item, variant: variant_2, stock_location: stock_location_2)
        end

        it "returns the expected notification" do
          expect( subject.map(&:id) ).to eq [bisn_1.id]
        end
      end
    end
  end
end
