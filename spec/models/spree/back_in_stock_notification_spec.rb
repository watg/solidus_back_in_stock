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
    end

    context "when the email is missing" do
      before { back_in_stock_notification.email = nil }

      it "does not save record" do
        expect{ subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the email is invalid" do
      before { back_in_stock_notification.email = "inavalid@email" }

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

    context "is not backorderable" do
      let(:backorderable) { false }

      context "item is in stock" do
        before do
          variant.stock_items.update_all count_on_hand: 50, backorderable: backorderable
        end

        it "returns one result" do
          expect(subject).to eq [back_in_stock_notification]
        end
      end

      context "item is out of stock" do
        before do
          variant.stock_items.update_all count_on_hand: 0, backorderable: backorderable
        end

        it "returns nothing" do
          expect(subject).to eq []
        end
      end
    end

    context "is backorderable" do
      let(:backorderable) { true }

      context "item is out of stock" do
        before do
          variant.stock_items.update_all count_on_hand: 0, backorderable: backorderable
        end

        it "returns one result" do
          expect(subject).to eq [back_in_stock_notification]
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
end
