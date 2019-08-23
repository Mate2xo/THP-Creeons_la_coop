# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "ProductorsRecapMaps", type: :feature do
  describe "address coordinates auto-search" do
    context "when a new productor is created" do
      let(:productor) { build :productor }

      context "and an address is given" do
        before {
          productor.address = build :address
          allow(productor.address).to receive(:fetch_coordinates)
        }

        it "fetches coordinates if no coordinates are given" do
          productor.address.coordinates = nil
          productor.save
          expect(productor.address).to have_received(:fetch_coordinates)
        end

        it "does not fetch coordinates if coordinates are given" do
          productor.save
          expect(productor.address).not_to have_received(:fetch_coordinates)
        end
      end
    end

    context "when a productor is updated" do
      let(:productor) { create :productor, address: create(:address) }

      context "and its address is also updated" do
        let(:new_address) { attributes_for :address }
        before { allow(productor.address).to receive(:fetch_coordinates) }

        it "fetches coordinates if no new coordinates are given" do
          productor.update(address: new_address)
        end

        it "does not fetch new coordinates if new coordinates are given" do
        end
      end

      context "and its address is not updated" do
        it "does not fetch coordinates" do
        end
      end
    end

    context "when an address that doesn't belong to a productor is saved," do
      let(:address) { build :address, coordinates: nil }

      it "doesn't launch Address#fetch_coordinates for a Member" do
        member = build :member
        member.address = address
        allow(member.address).to receive(:fetch_coordinates)

        member.save

        expect(member.address).not_to have_received(:fetch_coordinates)
      end

      it "doesn't launch Address#fetch_coordinates for a Mission" do
      end
    end
  end
end
