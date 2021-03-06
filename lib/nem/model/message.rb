module Nem
  module Model
    # @attr [String] value
    # @attr [Integer] type
    # @attr [String] public_key
    # @attr [String] private_key
    class Message
      TYPE_PLAIN     = 1
      TYPE_ENCRYPTED = 2

      include Nem::Mixin::Assignable

      attr_reader :value, :type
      attr_accessor :public_key, :private_key

      def self.new_from_message(hash)
        new(
          hash[:payload],
          type: (hash[:type] == TYPE_ENCRYPTED) ? :encrypted : :plain
        )
      end

      def initialize(value = '', type: :plain, private_key: nil, public_key: nil)
        @value = value
        @type = (type == :encrypted) ? TYPE_ENCRYPTED : TYPE_PLAIN
        @private_key = private_key
        @public_key = public_key
      end

      def encrypt!
        bin_sk = fix_private_key(@private_key).scan(/../).map(&:hex).reverse.pack('C*')
        bin_pk = (public_key || @public_key).scan(/../).map(&:hex).pack('C*')
        @value = Nem::Util::Ed25519.encrypt(bin_sk, bin_pk, value)
        @type = TYPE_ENCRYPTED
      end

      def decrypt!
        bin_sk = fix_private_key(@private_key).scan(/../).map(&:hex).reverse.pack('C*')
        bin_pk = (public_key || @public_key).scan(/../).map(&:hex).pack('C*')
        @value = Nem::Util::Ed25519.decrypt(bin_sk, bin_pk, payload)
        @type = TYPE_PLAIN
      end

      # @return [Boolean]
      def encrypted?
        @type == TYPE_ENCRYPTED
      end

      # @return [Boolean]
      def plain?
        @type == TYPE_PLAIN
      end

      # @return [Integer]
      def bytesize
        payload.bytesize
      end

      # @return [Boolean]
      def valid?
        bytesize <= 1024
      end

      # @return [Boolean]
      def hex?
        !!(value =~ /\Afe\h+\Z/)
      end

      # @return [Hash]
      def to_hash
        { payload: payload, type: type }
      end

      # @return [String]
      def to_s
        @value.to_s
      end

      # @return [Boolean]
      def ==(other)
        @value == other.value
      end

      # @return [String]
      def payload
        (hex? || encrypted?) ? value : value.unpack('H*').first
      end

      private

      def fix_private_key(key)
        "#{'0' * 64}#{key.sub(/^00/i, '')}"[-64, 64]
      end
    end
  end
end
